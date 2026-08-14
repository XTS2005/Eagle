import UIKit

extension UIImage {
    func resizeToApprox(allowedSizeInBytes: Int) throws -> Data {
        if let data = self.jpegData(compressionQuality: 0.99), data.count <= allowedSizeInBytes {
            return data
        }

        var left: CGFloat = 0.0
        var right: CGFloat = 1.0
        var mid = (left + right) / 2.0

        var closestImage: Data?
        guard var newResImage = self.jpegData(compressionQuality: 1) else {
            throw NSError(domain: "IconThemer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
        }

        for _ in 0...13 {
            if newResImage.count < allowedSizeInBytes {
                left = mid
                closestImage = newResImage
            } else if newResImage.count > allowedSizeInBytes {
                right = mid
            } else {
                return newResImage
            }

            mid = (left + right) / 2.0
            guard let newData = self.jpegData(compressionQuality: mid) else {
                throw NSError(domain: "IconThemer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not compress image"])
            }
            newResImage = newData
        }

        if let closestImage {
            return closestImage
        }

        throw NSError(domain: "IconThemer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not compress image low enough to fit inside the original size budget"])
    }
}
