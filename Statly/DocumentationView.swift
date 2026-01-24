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
                VStack(alignment: .leading, spacing: 24) {
                    Text("How Statly Fetches Your Stats")
                        .font(.title2)
                        .fontWeight(.semibold)

                    endpointSection
                    responseSection
                    tipsSection
                }
                .padding()
            }
            .navigationTitle("Documentation")
        }
    }

    // MARK: - Sections

    private var endpointSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("1. Create an HTTPS endpoint")
                .font(.headline)

            Text("""
            Statly calls a **single HTTP GET** endpoint you host.

            - **Method**: GET
            - **Auth header**: `api_key: YOUR_API_KEY`
            - **Content-Type (response)**: `application/json`
            - **Timeout**: ~30 seconds
            """)
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text("Example (Node/Express):")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 4)

            Text("""
            app.get("/statly", (req, res) => {
              const apiKey = req.header("api_key");
              if (apiKey !== process.env.STATLY_API_KEY) {
                return res.status(401).json({ error: "Unauthorized" });
              }

              const response = /* build StatsResponse JSON (see below) */;
              res.json(response);
            });
            """)
            .font(.system(.caption, design: .monospaced))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("2. Response JSON shape")
                .font(.headline)

            Text("""
            Statly expects a JSON body matching this structure:

            - **stats**: array of individual stat objects
            - **updatedAt** (optional): ISO 8601 timestamp string

            Each **stat**:
            - **label**: short name to display (e.g. \"USERS\")
            - **value**: already formatted string (e.g. \"1,234\" or \"$45.2K\")
            - **trend** (optional): string like \"+12%\" or \"-5%\"
            - **trendDirection** (optional): one of `\"up\"`, `\"down\"`, `\"neutral\"`
            """)
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text("Example response:")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 4)

            Text("""
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
            .font(.system(.caption, design: .monospaced))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("3. Recommendations")
                .font(.headline)

            Text("""
            - **Keep it fast**: aim for < 3 seconds response time.
            - **Do formatting on your side**: send human-readable `value` strings.
            - **Pick clear labels**: short, uppercase labels work best on widgets.
            - **Optional fields**: `trend` and `trendDirection` can be omitted if you don't track them.
            - **Multiple widgets**: you can serve the same endpoint to multiple widgets
              with different styling and refresh intervals inside the app.
            """)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DocumentationView()
}

