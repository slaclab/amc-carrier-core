#-----------------------------------------------------------------------------
# Title      : JESD RX eye scan runner for AmcCarrierCore applications
#-----------------------------------------------------------------------------
# Description:
# The application side of a JESD204b RX eye scan on the surf eye-scan runner
# (surf.xilinx.eyescan.runEyeScan), shared by every AmcCarrierCore based
# project: the argument set, the bay and lane selection, the line rate check,
# the JESD link check and bring-up around the scan, and the single runEyeScan
# call over the selected lanes. An application script only builds its root
# and passes the hooks that depend on its AMC card (line rate measurement,
# link check and bring-up).
#
# The only RX reset of a bay is JesdRx.ResetGTs, which AppTopJesd204b feeds to
# gtwiz_reset_all: every GT of the bay, RX and TX. The lanes therefore scan one
# at a time (--parallel false is enforced) and the JESD bring-up runs again
# after the scan so the TX (DAC) link comes back.
#-----------------------------------------------------------------------------
# This file is part of the rogue software platform. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the rogue software platform, including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import os
import time
import dataclasses

import surf.xilinx.eyescan as es
import surf.protocols.jesd204b as jesd

__all__ = ['JesdRxEyeScanPlan', 'addJesdRxEyeScanArguments', 'prepareJesdRxEyeScan',
           'runJesdRxEyeScan', 'waitRssiLink', 'checkJesdRxLinks', 'removeEmptyFolder']

# Allowed relative gap between --lineRate and the rate measured on the hardware
LINE_RATE_TOLERANCE = 0.01


@dataclasses.dataclass
class JesdRxEyeScanPlan:
    """Checked selection of a JESD RX eye scan, made before the hardware is touched."""
    plan: es.EyeScanPlan      # run folder and the lane list within a bay
    bays: list                # selected bays
    stride: int               # flat lane label = bay * stride + lane
    laneIds: dict             # flat lane label -> (bay, lane)


def addJesdRxEyeScanArguments(parser):
    """Add the JESD selection options and the surf eye-scan options to an argparse parser.

    The receivers of the carrier GT wrappers run in LPM mode and the RX reset
    is shared by the bay, so the defaults are ``--equalizer lpm`` and
    ``--parallel false``. ``--lineRate`` has no useful default here: the
    application states the serial rate of its image and
    ``prepareJesdRxEyeScan`` refuses a run without it.
    """
    parser.add_argument("--bays", type=str, default=None,
                        help="AMC bays to scan, e.g. 0, 1 or 0,1 (default: every bay with JESD RX lanes). "
                             "--lanes selects the lanes within each bay.")
    parser.add_argument("--settle", type=float, default=3.0,
                        help="Seconds the JESD link is given to settle before its health is judged")
    parser.add_argument("--noBringUp", dest='bringUp', action='store_false',
                        help="Skip the JESD link check before the scan and the bring-up after it. "
                             "By default the link is checked (and brought up if needed) first, and brought "
                             "up again afterwards because the shared GT reset drops the TX/DAC link too. "
                             "With this flag the link is left as the scan left it.")
    parser.add_argument("--force", action='store_true',
                        help="Scan anyway when the measured line rate disagrees with --lineRate or the "
                             "JESD link cannot be brought up")
    es.addEyeScanArguments(parser)
    parser.set_defaults(equalizer='lpm', parallel=False)
    # The runner's help of two options does not hold here
    parser._option_string_actions['--lineRate'].help = (
        'line rate in Gb/s of this image, required; checked against the hardware before the scan')
    parser._option_string_actions['--parallel'].help = (
        'must stay false: JesdRx.ResetGTs resets every GT of the bay, so the lanes scan one at a time')
    return parser


def parseBays(text, numRxLanes):
    """Return the selected bay list: every bay with RX lanes, or the ones named in text."""
    withLanes = [bay for bay, lanes in enumerate(numRxLanes) if lanes > 0]
    if text is None:
        return withLanes
    bays = []
    for item in text.split(','):
        item = item.strip()
        if not item.isdigit() or int(item) >= len(numRxLanes):
            raise ValueError(f'invalid bay {item!r}; the carrier has bays {list(range(len(numRxLanes)))}')
        bay = int(item)
        if bay not in withLanes:
            raise ValueError(f'bay {bay} has no JESD RX lanes in this firmware (numRxLanes={numRxLanes})')
        if bay not in bays:
            bays.append(bay)
    return bays


def prepareJesdRxEyeScan(parser, args, numRxLanes):
    """Check the arguments against the lane counts and create the run folder, before the hardware is touched.

    Parameters
    ----------
    parser : argparse.ArgumentParser
        Reports a refused selection through ``parser.error``.
    args : argparse.Namespace
        Parsed arguments of a parser built with ``addJesdRxEyeScanArguments``.
    numRxLanes : list of int
        RX lane count per bay (``AppTop._numRxLanes``).

    Returns
    -------
    JesdRxEyeScanPlan
    """
    if args.lineRate <= 0.0:
        parser.error('--lineRate is required: the serial rate in Gb/s of this image, '
                     'checked against the hardware before the scan')
    if args.parallel:
        parser.error('--parallel true is not possible: JesdRx.ResetGTs resets every GT of the bay, '
                     'so the lanes must scan one at a time')
    try:
        bays = parseBays(args.bays, numRxLanes)
    except ValueError as e:
        parser.error(str(e))
    if not bays:
        parser.error(f'this firmware has no JESD RX lanes (numRxLanes={numRxLanes})')
    stride = max(numRxLanes)

    # --lanes is validated against the largest bay; by default every lane of
    # each bay is scanned, and an explicit lane that a selected bay lacks is refused
    try:
        plan = es.prepareEyeScan(args, stride)
    except ValueError as e:
        parser.error(str(e))
    laneIds = {}
    for bay in bays:
        lanes = [lane for lane in plan.lanes if lane < numRxLanes[bay]]
        if args.lanes is not None and len(lanes) != len(plan.lanes):
            removeEmptyFolder(plan.folder)
            missing = [lane for lane in plan.lanes if lane >= numRxLanes[bay]]
            parser.error(f'bay {bay} has {numRxLanes[bay]} RX lanes, no lane {missing}')
        for lane in lanes:
            laneIds[bay * stride + lane] = (bay, lane)
    return JesdRxEyeScanPlan(plan=plan, bays=bays, stride=stride, laneIds=laneIds)


def removeEmptyFolder(folder):
    """Remove the run folder when nothing was written into it."""
    if folder is not None and os.path.isdir(folder) and not os.listdir(folder):
        os.rmdir(folder)


def waitRssiLink(rudp, timeout=10.0):
    """Wait up to ``timeout`` seconds for a ``UdpRssiPack`` opened with ``wait=False``; return True when it is up.

    The default ``wait=True`` of UdpRssiPack blocks forever on a board that
    does not answer; an application root opens the link without waiting and
    calls this after ``start()`` to bound the wait.
    """
    deadline = time.monotonic() + timeout
    while not rudp.rssiOpen.get():
        if time.monotonic() > deadline:
            return False
        time.sleep(0.1)
    return True


def checkJesdRxLinks(appTop):
    """Default link check: every enabled RX lane of every bay reports DataValid. Returns (ok, [reasons])."""
    bad = []
    for dev in appTop.find(typ=jesd.JesdRx):
        enable = int(dev.Enable.get())
        valid = int(dev.DataValid.get())
        if enable and valid != enable:
            bad.append(f'{dev.path}: DataValid 0x{valid:X} != Enable 0x{enable:X}')
    return (not bad), bad


def runJesdRxEyeScan(args, jesdPlan, root, appTop, *, version=None, measureLineRate=None,
                     checkLink=None, bringUpLink=None, dumpLink=None, extraMeta=None):
    """Run the eye scan over the selected JESD RX lanes of a started root. Returns the exit code.

    Parameters
    ----------
    args : argparse.Namespace
        Parsed arguments of a parser built with ``addJesdRxEyeScanArguments``.
    jesdPlan : JesdRxEyeScanPlan
        Result of ``prepareJesdRxEyeScan``.
    root : pyrogue.Root
        Started root whose link to the board is proven.
    appTop : AmcCarrierCore.AppTop.AppTop
        Device that owns the ``AppTopJesd[bay]`` instances.
    version : AxiVersion, optional
        Printed and recorded as card information.
    measureLineRate : callable, optional
        ``measureLineRate(bay) -> (clockHz, lineRateGbps)`` read from the
        hardware; the run aborts when it disagrees with ``--lineRate`` by
        more than 1 % unless ``--force``. None skips the check.
    checkLink : callable, optional
        ``checkLink() -> (ok, [reasons])``; default ``checkJesdRxLinks(appTop)``.
    bringUpLink : callable, optional
        ``bringUpLink() -> (ok, [reasons])``; default ``appTop.Init()`` then
        ``checkLink()``. Runs before the scan when the check fails and after
        every scan, because the shared GT reset drops the TX link.
    dumpLink : callable, optional
        Diagnostic printed when the bring-up fails.
    extraMeta : dict, optional
        Application fields added to the metadata of every lane.
    """
    plan, bays, stride, laneIds = jesdPlan.plan, jesdPlan.bays, jesdPlan.stride, jesdPlan.laneIds

    if checkLink is None:
        def checkLink():
            return checkJesdRxLinks(appTop)
    if bringUpLink is None:
        def bringUpLink():
            appTop.Init()
            time.sleep(args.settle)
            return checkLink()

    code = 0
    scanned = False          # a scan pulsed the shared GT reset, so the TX side needs its bring-up
    try:
        # Fill every register shadow from the hardware: pyrogue writes a word
        # from its shadow, so a pulsed bit (ResetGTs, ClearErrors) must not
        # take its neighbours (SubClass, ScrambleEnable) along as zeros
        root.ReadAll()

        # The JESD link must be up: a lane whose DataValid never rises can only
        # end NOT_ENABLED. Status mode writes nothing, so it skips this.
        if args.bringUp and args.mode != 'Status':
            ok, reasons = checkLink()
            if not ok:
                print('JESD link is not healthy, running the bring-up first:')
                for reason in reasons:
                    print(f'  {reason}')
                ok, reasons = bringUpLink()
            if not ok:
                if dumpLink is not None:
                    dumpLink()
                if not args.force:
                    print('JESD bring-up failed; pass --force to scan anyway')
                    return 2
                print('JESD bring-up failed, scanning anyway (--force)')

        # Line rate: defined by --lineRate, checked against the hardware per bay
        rates = {}
        for bay in bays:
            if measureLineRate is None:
                continue
            clock, measured = measureLineRate(bay)
            rates[bay] = {'clockHz': clock, 'measuredLineRateGbps': measured}
            gap = abs(measured - args.lineRate) / args.lineRate
            print(f'Bay {bay}: clock {clock} Hz -> {measured:.4f} Gb/s on the wire '
                  f'(requested {args.lineRate:g} Gb/s, gap {100.0 * gap:.2f} %)')
            if gap > LINE_RATE_TOLERANCE:
                if not args.force:
                    print(f'--lineRate {args.lineRate:g} disagrees with the hardware by more than '
                          f'{100.0 * LINE_RATE_TOLERANCE:.0f} %; rerun with --lineRate {measured:.3f} '
                          f'or pass --force')
                    return 2
                print('line rate mismatch ignored (--force)')

        # One target per selected lane, labelled with the flat index. A lane that
        # is not enabled in JesdRx can never report DataValid, so it is skipped.
        targets = []
        enables = {}
        for bay in bays:
            jesdTop = appTop.AppTopJesd[bay]
            enable = int(jesdTop.JesdRx.Enable.get())
            enables[bay] = f'0x{enable:X}'
            byLane = {target.lane: target for target in jesdTop.eyeScanLanes()}
            for laneId, (b, lane) in laneIds.items():
                if b != bay:
                    continue
                if not (enable >> lane) & 1:
                    print(f'Bay {bay}: lane {lane} is not enabled in JesdRx (Enable=0x{enable:X}), skipping it')
                    continue
                target = byLane[lane]
                targets.append(es.EyeScanLane(lane=laneId, gt=target.gt, link=target.link))
        if not targets:
            print('No enabled lane left to scan')
            return 2
        runPlan = es.EyeScanPlan(lanes=[target.lane for target in targets], folder=plan.folder)

        print('Lanes: ' + ', '.join(f'Lane[{target.lane}] = bay {laneIds[target.lane][0]} lane {laneIds[target.lane][1]}'
                                    for target in targets))
        meta = {
            'laneStride' : stride,
            'bays'       : {str(bay): dict(rates.get(bay, {}), jesdRxEnable=enables[bay]) for bay in bays},
            'resetScope' : 'JesdRx.ResetGTs resets every GT of the bay (RX and TX)',
        }
        if extraMeta:
            meta.update(extraMeta)
        try:
            code = es.runEyeScan(args, runPlan, targets, version=version, extraMeta=meta)
            scanned = args.mode != 'Status'
        except KeyboardInterrupt:
            print('Interrupted')
            scanned = args.mode != 'Status'
            code = 2
        except ValueError as e:
            # The runner refused a lane before any write (and removed the empty run folder)
            print(f'Scan refused: {e}')
            code = 2
    finally:
        removeEmptyFolder(plan.folder)
        # The shared GT reset dropped the TX/DAC link: bring the JESD link back
        if args.bringUp and scanned:
            print('Restoring the JESD link after the scan')
            ok, reasons = bringUpLink()
            if ok:
                print('JESD link is healthy')
            else:
                print('WARNING: the JESD link did not come back after the scan:')
                for reason in reasons:
                    print(f'  {reason}')
                if dumpLink is not None:
                    dumpLink()
                code = max(code, 2)

    return code
