import Foundation

private struct MatrixCase {
    let name: String
    let version: OperatingSystemVersion
    let machine: String
    let build: String?
    let expectedStatus: EagleSupportStatus
    let expectedReason: EagleSupportReason
}

private struct PrepareGateCase {
    let name: String
    let version: OperatingSystemVersion
    let machine: String
    let expectedAllowsPrepare: Bool
}

@main
private enum VerifyPrepareSupportMatrix {
    static func main() {
#if EAGLE_A18_PREPARE_LAB
        let exactFieldStatus = EagleSupportStatus.possible
        let exactFieldReason = EagleSupportReason.iphone16IOS185KernelStageLab
#else
        let exactFieldStatus = EagleSupportStatus.unsupported
        let exactFieldReason = EagleSupportReason.iphone16IOS185FieldRestart
#endif
        let cases = [
            MatrixCase(
                name: "proven iPhone 16 Pro remains supported",
                version: OperatingSystemVersion(
                    majorVersion: 18,
                    minorVersion: 6,
                    patchVersion: 2
                ),
                machine: "iPhone17,1",
                build: "22G100",
                expectedStatus: .supported,
                expectedReason: .ios17Through1871
            ),
            MatrixCase(
                name: "field-restarting tuple follows the selected build route",
                version: OperatingSystemVersion(
                    majorVersion: 18,
                    minorVersion: 5,
                    patchVersion: 0
                ),
                machine: "iPhone17,3",
                build: "22F76",
                expectedStatus: exactFieldStatus,
                expectedReason: exactFieldReason
            ),
            MatrixCase(
                name: "pure callers fail closed when the risky build is unknown",
                version: OperatingSystemVersion(
                    majorVersion: 18,
                    minorVersion: 5,
                    patchVersion: 0
                ),
                machine: "iPhone17,3",
                build: nil,
                expectedStatus: .unsupported,
                expectedReason: .iphone16IOS185FieldRestart
            ),
            MatrixCase(
                name: "unverified iPhone 16 iOS 18.5 builds remain blocked",
                version: OperatingSystemVersion(
                    majorVersion: 18,
                    minorVersion: 5,
                    patchVersion: 0
                ),
                machine: "iPhone17,3",
                build: "22F77",
                expectedStatus: .unsupported,
                expectedReason: .iphone16IOS185FieldRestart
            ),
            MatrixCase(
                name: "blank build fails closed on the risky family",
                version: OperatingSystemVersion(
                    majorVersion: 18,
                    minorVersion: 5,
                    patchVersion: 0
                ),
                machine: "iPhone17,3",
                build: "   ",
                expectedStatus: .unsupported,
                expectedReason: .iphone16IOS185FieldRestart
            ),
            MatrixCase(
                name: "iPhone 16 Plus is not inferred from iPhone 16 report",
                version: OperatingSystemVersion(
                    majorVersion: 18,
                    minorVersion: 5,
                    patchVersion: 0
                ),
                machine: "iPhone17,4",
                build: "22F76",
                expectedStatus: .supported,
                expectedReason: .ios17Through1871
            ),
            MatrixCase(
                name: "iPhone 16 newer release follows the normal matrix",
                version: OperatingSystemVersion(
                    majorVersion: 18,
                    minorVersion: 6,
                    patchVersion: 2
                ),
                machine: "iPhone17,3",
                build: "22G100",
                expectedStatus: .supported,
                expectedReason: .ios17Through1871
            ),
            MatrixCase(
                name: "MIE hardware remains blocked",
                version: OperatingSystemVersion(
                    majorVersion: 18,
                    minorVersion: 7,
                    patchVersion: 1
                ),
                machine: "iPhone18,1",
                build: "22H999",
                expectedStatus: .unsupported,
                expectedReason: .memoryIntegrityEnforcement
            ),
        ]

        var failures = 0
        for test in cases {
            let assessment = eagleSupportAssessment(
                version: test.version,
                machine: test.machine,
                systemBuild: test.build
            )
            guard assessment.status == test.expectedStatus,
                  assessment.reason == test.expectedReason else {
                failures += 1
                fputs(
                    "FAIL: \(test.name): got \(assessment.status.rawValue) " +
                        "[\(assessment.reason.rawValue)]\n",
                    stderr
                )
                continue
            }
            print("PASS: \(test.name)")
        }

        let gateCases = [
            PrepareGateCase(
                name: "unverified iOS 16.1 fails closed",
                version: .init(majorVersion: 16, minorVersion: 1, patchVersion: 0),
                machine: "iPhone15,3",
                expectedAllowsPrepare: false
            ),
            PrepareGateCase(
                name: "unverified iOS 16.1.1 fails closed",
                version: .init(majorVersion: 16, minorVersion: 1, patchVersion: 1),
                machine: "iPhone15,3",
                expectedAllowsPrepare: false
            ),
            PrepareGateCase(
                name: "unverified iOS 16.2 fails closed",
                version: .init(majorVersion: 16, minorVersion: 2, patchVersion: 0),
                machine: "iPhone15,3",
                expectedAllowsPrepare: false
            ),
            PrepareGateCase(
                name: "tested iOS 16.7.2 remains available",
                version: .init(majorVersion: 16, minorVersion: 7, patchVersion: 2),
                machine: "iPhone11,6",
                expectedAllowsPrepare: true
            ),
            PrepareGateCase(
                name: "iOS 18.7.1 boundary remains available",
                version: .init(majorVersion: 18, minorVersion: 7, patchVersion: 1),
                machine: "iPhone16,2",
                expectedAllowsPrepare: true
            ),
            PrepareGateCase(
                name: "iOS 18.7.2 boundary is blocked",
                version: .init(majorVersion: 18, minorVersion: 7, patchVersion: 2),
                machine: "iPhone16,2",
                expectedAllowsPrepare: false
            ),
            PrepareGateCase(
                name: "iOS 26.0.1 boundary remains available",
                version: .init(majorVersion: 26, minorVersion: 0, patchVersion: 1),
                machine: "iPhone17,1",
                expectedAllowsPrepare: true
            ),
            PrepareGateCase(
                name: "iOS 26.0.2 is blocked",
                version: .init(majorVersion: 26, minorVersion: 0, patchVersion: 2),
                machine: "iPhone17,1",
                expectedAllowsPrepare: false
            ),
            PrepareGateCase(
                name: "iOS 26.6 is blocked",
                version: .init(majorVersion: 26, minorVersion: 6, patchVersion: 0),
                machine: "iPhone17,1",
                expectedAllowsPrepare: false
            ),
        ]

        for test in gateCases {
            let assessment = eagleSupportAssessment(
                version: test.version,
                machine: test.machine
            )
            guard assessment.allowsPrepare == test.expectedAllowsPrepare else {
                failures += 1
                fputs(
                    "FAIL: \(test.name): allowsPrepare=\(assessment.allowsPrepare) " +
                        "[\(assessment.reason.rawValue)]\n",
                    stderr
                )
                continue
            }
            print("PASS: \(test.name)")
        }

        if failures > 0 {
            exit(1)
        }
    }
}
