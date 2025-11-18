//
//  OrderRowView.swift
//  HappyLaunderer
//
//  Row view for displaying an order in a list
//

import SwiftUI

struct OrderRowView: View {
    let order: Order
    
    var body: some View {
        HStack(spacing: 15) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: order.status.systemImage)
                    .foregroundColor(statusColor)
                    .font(.title3)
            }
            
            // Order details
            VStack(alignment: .leading, spacing: 5) {
                Text(order.status.displayName)
                    .font(.headline)
                
                Text(order.serviceType.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(order.scheduledTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Price
            VStack(alignment: .trailing, spacing: 5) {
                Text("$\(String(format: "%.2f", order.price))")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var statusColor: Color {
        switch order.status {
        case .pending:
            return .orange
        case .pickedUp, .inLaundry:
            return .blue
        case .ready:
            return .green
        case .outForDelivery:
            return .purple
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    OrderRowView(order: Order(
        id: "1",
        userId: "1",
        pickupAddress: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102", latitude: nil, longitude: nil),
        deliveryAddress: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102", latitude: nil, longitude: nil),
        scheduledTime: Date(),
        status: .pending,
        serviceType: .express,
        itemCount: 5,
        price: 40.00,
        driverId: nil,
        driverLocation: nil,
        notes: nil,
        createdAt: Date(),
        updatedAt: Date()
    ))
}

