//
//  APIErrorView.swift
//  JisuitaApp
//
//  Created by 株式会社オフィス岳 on 2026/04/10.
//

import SwiftUI

struct APIErrorBanner: View {
    let error: APIError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(error.errorDescription ?? "エラーが発生しました")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if error.isRetryable, let onRetry {
                Button(action: onRetry) {
                    Text("再試行する")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(hex: "1D9E75"))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct APIErrorAlert: ViewModifier {
    @Binding var error: APIError?
    let onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                "通信エラー",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { err in
                if err.isRetryable, let onRetry {
                    Button("再試行") {
                        error = nil
                        onRetry()
                    }
                }
                Button("閉じる", role: .cancel) {
                    error = nil
                }
            } message: { err in
                Text(err.errorDescription ?? "エラーが発生しました")
            }
    }
}

extension View {
    func apiErrorAlert(error: Binding<APIError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(APIErrorAlert(error: error, onRetry: onRetry))
    }
}
