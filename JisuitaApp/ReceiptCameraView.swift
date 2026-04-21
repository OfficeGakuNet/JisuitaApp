import SwiftUI
import AVFoundation

struct ReceiptCameraView: View {
    @State private var showReview = false
    @State private var capturedImage: UIImage?

    var body: some View {
        ZStack {
            CameraPreviewRepresentable()
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text("枠内にレシートを収めてください")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.top, 60)

                Spacer()

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "1D9E75"), lineWidth: 3)
                    .frame(width: 300, height: 420)
                    .overlay(
                        VStack {
                            HStack {
                                cornerMark(rotation: 0)
                                Spacer()
                                cornerMark(rotation: 90)
                            }
                            Spacer()
                            HStack {
                                cornerMark(rotation: 270)
                                Spacer()
                                cornerMark(rotation: 180)
                            }
                        }
                        .padding(8)
                    )

                Spacer()

                Button(action: { showReview = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(Color(hex: "1D9E75"))
                            .frame(width: 60, height: 60)
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("レシートを撮影")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .navigationDestination(isPresented: $showReview) {
            ReceiptReviewView()
        }
    }

    private func cornerMark(rotation: Double) -> some View {
        Image(systemName: "l.square")
            .foregroundColor(Color(hex: "1D9E75"))
            .font(.caption)
            .rotationEffect(.degrees(rotation))
            .opacity(0)
    }
}

private struct CameraPreviewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }
        session.addInput(input)

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = UIScreen.main.bounds
        view.layer.addSublayer(preview)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    NavigationStack {
        ReceiptCameraView()
    }
}
