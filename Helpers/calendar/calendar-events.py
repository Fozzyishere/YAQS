#!/usr/bin/env python3
import gi

gi.require_version('EDataServer', '1.2')
gi.require_version('ECal', '2.0')
import json
import sys
import time
from datetime import datetime, timezone

from gi.repository import ECal, EDataServer

# Parse command-line arguments (Unix timestamps)
if len(sys.argv) < 3:
    print("Error: Missing arguments. Usage: calendar-events.py <start_time> <end_time>", file=sys.stderr)
    sys.exit(1)

start_time = int(sys.argv[1])
end_time = int(sys.argv[2])

print(f"Starting with time range: {start_time} to {end_time}", file=sys.stderr)

all_events = []

def safe_get_time(ical_time):
    """Safely get time from ICalTime object with defensive validation."""
    if not ical_time:
        return None

    try:
        year = ical_time.get_year()
        month = ical_time.get_month()
        day = ical_time.get_day()

        # Validate date ranges
        if year < 1970 or year > 2100 or month < 1 or month > 12 or day < 1 or day > 31:
            return None

        # Handle all-day events (date only, no time)
        if ical_time.is_date():
            local_struct = time.struct_time((year, month, day, 0, 0, 0, 0, 0, -1))
            return int(time.mktime(local_struct))

        # Handle timed events (date + time)
        hour = ical_time.get_hour()
        minute = ical_time.get_minute()
        second = ical_time.get_second()

        dt = datetime(year, month, day, hour, minute, second, tzinfo=timezone.utc)
        return int(dt.timestamp())
    except Exception as e:
        print(f"  Error parsing time: {e}", file=sys.stderr)
        return None

print("Getting registry...", file=sys.stderr)
registry = EDataServer.SourceRegistry.new_sync(None)
print("Registry obtained", file=sys.stderr)

sources = registry.list_sources(EDataServer.SOURCE_EXTENSION_CALENDAR)
print(f"Found {len(sources)} calendar sources", file=sys.stderr)

for source in sources:
    # Skip disabled calendars
    if not source.get_enabled():
        print(f"Skipping disabled calendar: {source.get_display_name()}", file=sys.stderr)
        continue

    calendar_name = source.get_display_name()
    print(f"\nProcessing calendar: {calendar_name}", file=sys.stderr)

    try:
        print(f"  Connecting to {calendar_name}...", file=sys.stderr)
        client = ECal.Client.connect_sync(
            source,
            ECal.ClientSourceType.EVENTS,
            30,  # Timeout (seconds)
            None
        )
        print(f"  Connected to {calendar_name}", file=sys.stderr)

        # Convert timestamps to ISO 8601 format for query
        start_dt = datetime.fromtimestamp(start_time, tz=timezone.utc)
        end_dt = datetime.fromtimestamp(end_time, tz=timezone.utc)

        start_str = start_dt.strftime("%Y%m%dT%H%M%SZ")
        end_str = end_dt.strftime("%Y%m%dT%H%M%SZ")

        # Build EDS query for time range
        query = f'(occur-in-time-range? (make-time "{start_str}") (make-time "{end_str}"))'
        print(f"  Query: {query}", file=sys.stderr)

        print(f"  Getting object list for {calendar_name}...", file=sys.stderr)
        success, ical_objects = client.get_object_list_sync(query, None)
        print(f"  Got object list for {calendar_name}: success={success}, count={len(ical_objects) if ical_objects else 0}", file=sys.stderr)

        if not success or not ical_objects:
            print(f"  No events found in {calendar_name}", file=sys.stderr)
            continue

        print(f"  Processing {len(ical_objects)} events from {calendar_name}...", file=sys.stderr)
        for idx, ical_obj in enumerate(ical_objects):
            try:
                # Handle different object types
                if hasattr(ical_obj, 'get_summary'):
                    comp = ical_obj
                else:
                    comp = ECal.Component.new_from_string(ical_obj)

                if not comp:
                    continue

                # Extract event properties
                summary = comp.get_summary() or "(No title)"

                # Parse start time (required)
                start_timestamp = safe_get_time(comp.get_dtstart())
                if start_timestamp is None:
                    continue

                # Parse end time (with fallback)
                end_timestamp = safe_get_time(comp.get_dtend())
                if end_timestamp is None or end_timestamp == start_timestamp:
                    # Default to 1-hour duration if end time missing or invalid
                    end_timestamp = start_timestamp + 3600

                location = comp.get_location() or ""
                description = comp.get_description() or ""

                all_events.append({
                    'summary': summary,
                    'start': start_timestamp,
                    'end': end_timestamp,
                    'location': location,
                    'description': description,
                    'calendar': calendar_name
                })

                # Progress logging every 10 events
                if (idx + 1) % 10 == 0:
                    print(f"  Processed {idx + 1} events from {calendar_name}...", file=sys.stderr)
            except Exception as e:
                print(f"  Error processing event {idx} in {calendar_name}: {e}", file=sys.stderr)
                continue

        print(f"  Finished processing {calendar_name}, found {len([e for e in all_events if e['calendar'] == calendar_name])} events", file=sys.stderr)

    except Exception as e:
        print(f"  Error for {calendar_name}: {e}", file=sys.stderr)

# Sort by start time
print(f"\nSorting {len(all_events)} total events...", file=sys.stderr)
all_events.sort(key=lambda x: x['start'])
print("Done! Outputting JSON...", file=sys.stderr)

# Output JSON to stdout
print(json.dumps(all_events))

