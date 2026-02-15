# Events Management Guide

## Overview
Events are now stored in a simple CSV file (`data/events.csv`) which can be easily edited in Excel, Google Sheets, or any text editor.

## How to Edit Events

### Option 1: Edit with Excel/Google Sheets (Recommended)
1. Open `data/events.csv` with Excel or import it into Google Sheets
2. Edit the event data directly in the spreadsheet
3. Save the file in CSV format
4. Upload the updated file to your website

### Option 2: Edit with Text Editor
1. Open `data/events.csv` in any text editor (Notepad, VS Code, etc.)
2. Follow the CSV format shown below
3. Save the file

## CSV Format

The CSV file has the following columns:

| Column | Description | Example |
|--------|-------------|---------|
| `id` | Unique event ID | 1 |
| `title` | Event title | Community Clothing Drive |
| `date` | Event date (YYYY-MM-DD format) | 2025-10-04 |
| `families_served` | Number of families served | 204 |
| `clothes_lbs_distributed` | Total pounds of clothing distributed | 306 |
| `hours_volunteered` | Total volunteer hours | 98 |
| `description` | Event description | Our first major clothing drive |
| `image` | Path to event image | ../images/event1.jpg |

## Adding a New Event

Simply add a new row to the CSV file with all the required information:

```
4,New Event,2026-03-15,150,250,85,Description of the event,../images/event4.jpg
```

## Important Notes

- **Date Format**: Always use YYYY-MM-DD format (e.g., 2026-03-15)
- **IDs**: Make sure each event has a unique ID number
- **Numbers**: Keep `families_served`, `clothes_lbs_distributed`, and `hours_volunteered` as numbers only (no commas)
- **CSV Format**: When saving from Excel/Sheets, make sure you export as CSV format
- **Images**: Make sure the image files exist in the `images/` folder and paths are correct

## What Updates Automatically

When you update the CSV file:
- The homepage counters update automatically (Families Served, Lbs Distributed, Volunteer Hours)
- The Events page gallery updates with new events
- All changes are reflected immediately when you refresh the website

## Uploading Updated Files

After editing `events.csv`:
1. Save the file
2. Upload it to your web server via FTP or your hosting panel
3. Replace the old `data/events.csv` file
4. Refresh your website to see the changes

## Future Enhancements

If you want more advanced features in the future, you can:
- Set up a backend database (SQL, MongoDB, etc.)
- Create an admin panel to manage events through the web interface
- Add more event fields or filtering options

For now, the CSV format keeps things simple and manageable!
