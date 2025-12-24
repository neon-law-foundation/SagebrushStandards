#!/bin/bash
# Export ERD diagram to various formats

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "📊 Exporting ERD diagram..."

# Check if mermaid-cli is installed
if ! command -v mmdc &> /dev/null; then
    echo "⚠️  Mermaid CLI not found. Installing..."
    npm install -g @mermaid-js/mermaid-cli
fi

# Export to different formats
echo "📄 Generating PDF..."
mmdc -i ERD.md -o ERD.pdf -b transparent

echo "🖼️  Generating PNG..."
mmdc -i ERD.md -o ERD.png -b transparent -w 2400

echo "🎨 Generating SVG..."
mmdc -i ERD.md -o ERD.svg -b transparent

echo "✅ Export complete!"
echo ""
echo "Generated files:"
echo "  - ERD.pdf"
echo "  - ERD.png"
echo "  - ERD.svg"
echo ""
echo "To view:"
echo "  open ERD.pdf"
