import SwiftUI
import SwiftData
import AVFoundation

// MARK: - Barcode Scanner Camera
struct BarcodeCameraView: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerController {
        let controller = BarcodeScannerController()
        controller.onBarcodeScanned = onBarcodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerController, context: Context) {}
}

class BarcodeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let barcode = object.stringValue else { return }
        hasScanned = true
        captureSession?.stopRunning()
        onBarcodeScanned?(barcode)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

// MARK: - Barcode Scanner View
struct BarcodeScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scannedBarcode: String?
    @State private var product: BarcodeProduct?
    @State private var isLooking = false
    @State private var errorMessage: String?
    @State private var saved = false

    private let service = BarcodeLookupService()

    var body: some View {
        VStack(spacing: 0) {
            if scannedBarcode == nil {
                // Camera view
                ZStack {
                    BarcodeCameraView { barcode in
                        scannedBarcode = barcode
                        Task { await lookupBarcode(barcode) }
                    }

                    // Scan guide overlay
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.gold, lineWidth: 2)
                            .frame(width: 280, height: 120)
                        Spacer()
                        Text("Point camera at a barcode")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.bottom, 40)
                    }
                }
            } else {
                // Result
                ScrollView {
                    VStack(spacing: 20) {
                        if isLooking {
                            VStack(spacing: 12) {
                                ProgressView().tint(AppTheme.gold)
                                Text("Looking up product...")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .luxuryCard(padding: 24)
                        }

                        if let error = errorMessage {
                            VStack(spacing: 12) {
                                Label(error, systemImage: "exclamationmark.triangle")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.negative)

                                Button {
                                    resetScanner()
                                } label: {
                                    Label("Scan Again", systemImage: "barcode.viewfinder")
                                        .luxuryButton()
                                }
                            }
                            .luxuryCard()
                        }

                        if let product = product {
                            productResultView(product)
                        }
                    }
                    .padding()
                }
                .background(AppTheme.background)
            }
        }
        .navigationTitle("Barcode Scanner")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func productResultView(_ product: BarcodeProduct) -> some View {
        VStack(spacing: 16) {
            // Product name
            Text(product.name)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            // Calories
            VStack(spacing: 4) {
                Text("\(Int(product.calories))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.gold)
                Text("kcal per \(product.servingSize)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            // Macros
            HStack(spacing: 24) {
                MacroPill(label: "Protein", value: product.proteinGrams, color: AppTheme.positive)
                MacroPill(label: "Carbs", value: product.carbsGrams, color: AppTheme.gold)
                MacroPill(label: "Fat", value: product.fatGrams, color: AppTheme.warning)
            }

            // Save button
            Button {
                saveScannedMeal(product)
            } label: {
                Label("Log This Food", systemImage: "checkmark.circle.fill")
                    .luxuryButton()
            }

            if saved {
                Label("Saved!", systemImage: "checkmark")
                    .foregroundStyle(AppTheme.positive)
                    .transition(.opacity)
            }

            Button {
                resetScanner()
            } label: {
                Text("Scan Another")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.gold)
            }
        }
        .luxuryCard()
    }

    private func lookupBarcode(_ barcode: String) async {
        isLooking = true
        errorMessage = nil
        do {
            if let result = try await service.lookup(barcode: barcode) {
                product = result
            } else {
                errorMessage = "Product not found for barcode \(barcode). Try manual entry instead."
            }
        } catch {
            errorMessage = "Lookup failed: \(error.localizedDescription)"
        }
        isLooking = false
    }

    private func saveScannedMeal(_ product: BarcodeProduct) {
        let foodItem = FoodItem(
            name: product.name,
            calories: product.calories,
            portionSize: product.servingSize,
            proteinGrams: product.proteinGrams,
            carbsGrams: product.carbsGrams,
            fatGrams: product.fatGrams
        )
        let meal = Meal(
            foodItems: [foodItem],
            totalCalories: product.calories,
            timestamp: Date()
        )
        modelContext.insert(meal)
        WidgetSyncHelper.sync(context: modelContext)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
    }

    private func resetScanner() {
        scannedBarcode = nil
        product = nil
        errorMessage = nil
        saved = false
    }
}
