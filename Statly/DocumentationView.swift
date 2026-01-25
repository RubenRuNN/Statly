//
//  DocumentationView.swift
//  Statly
//
//  Simple in-app documentation explaining how to build
//  the metrics endpoint Statly expects.
//

import SwiftUI

struct DocumentationView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    endpointSection
                    responseSection
                    tipsSection
                }
                .padding()
            }
            .navigationTitle("Documentation")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How Statly Works")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Build a simple endpoint to display your stats on iOS widgets")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    private var endpointSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "1.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("Create an HTTPS Endpoint")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Statly calls a single HTTP GET endpoint you host.")
                    .font(.body)
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "arrow.right.circle", text: "Method: GET")
                    InfoRow(icon: "key.fill", text: "Auth header: api_key: YOUR_API_KEY")
                    InfoRow(icon: "doc.text", text: "Content-Type: application/json")
                    InfoRow(icon: "clock", text: "Timeout: ~30 seconds")
                }
                .padding(.top, 4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Example (Node/Express)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                CodeBlock(code: """
app.get("/statly", (req, res) => {
  const apiKey = req.header("api_key");
  if (apiKey !== process.env.STATLY_API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const response = /* build StatsResponse JSON (see below) */;
  res.json(response);
});
""")
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "2.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("Response JSON Structure")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Statly expects a JSON body matching this structure:")
                    .font(.body)
                    .foregroundStyle(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "list.bullet", text: "stats: array of stat objects")
                    InfoRow(icon: "clock.badge", text: "updatedAt (optional): ISO 8601 timestamp")
                }
                .padding(.top, 4)
                
                Text("Each stat object:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "tag", text: "label: short name (e.g., \"USERS\")")
                    InfoRow(icon: "number", text: "value: formatted string (e.g., \"1,234\" or \"$45.2K\")")
                    InfoRow(icon: "chart.line.uptrend.xyaxis", text: "trend (optional): string like \"+12%\" or \"-5%\"")
                    InfoRow(icon: "arrow.up.arrow.down", text: "trendDirection (optional): \"up\", \"down\", or \"neutral\"")
                }
                .padding(.top, 4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Example Response")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                CodeBlock(code: """
{
  "stats": [
    {
      "label": "USERS",
      "value": "1,234",
      "trend": "+12%",
      "trendDirection": "up"
    },
    {
      "label": "MRR",
      "value": "$45.2K",
      "trend": "-5%",
      "trendDirection": "down"
    },
    {
      "label": "CONVERSIONS",
      "value": "89",
      "trend": "0%",
      "trendDirection": "neutral"
    }
  ],
  "updatedAt": "2026-01-24T09:46:00Z"
}
""")
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "3.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("Best Practices")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                TipRow(icon: "bolt.fill", text: "Keep it fast: aim for < 3 seconds response time")
                TipRow(icon: "textformat", text: "Do formatting on your side: send human-readable value strings")
                TipRow(icon: "text.bubble", text: "Pick clear labels: short, uppercase labels work best")
                TipRow(icon: "checkmark.circle", text: "Optional fields: trend and trendDirection can be omitted")
                TipRow(icon: "square.grid.2x2", text: "Multiple widgets: serve the same endpoint to different widgets with custom styling")
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.tint)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

struct CodeBlock: View {
    let code: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DocumentationView()
}

