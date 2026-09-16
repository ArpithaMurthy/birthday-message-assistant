from __future__ import annotations

import argparse
import csv
import textwrap
import webbrowser
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from urllib.parse import urlencode


APP_NAME = "Moments Remembered"
APP_URL = "https://arpithamurthy.github.io/birthday-message-assistant/"
OUTBOX = Path("launch_outbox")
TRACKER = OUTBOX / "posting_tracker.csv"


@dataclass(frozen=True)
class LaunchDraft:
    channel: str
    title: str
    body: str
    url: str


DRAFTS = {
    "x": LaunchDraft(
        channel="X",
        title="Privacy-first occasion reminders",
        body=textwrap.dedent(
            f"""
            I built a tiny privacy-first app for people who remember birthdays too late or send generic last-minute messages.

            No login. No contact upload. Data stays in your browser.

            Add/import occasions -> calendar reminders -> WhatsApp/LINE/SMS drafts.

            Try it: {APP_URL}

            Is this useful or too much friction?
            """
        ).strip(),
        url="https://twitter.com/intent/tweet",
    ),
    "reddit_sideproject": LaunchDraft(
        channel="Reddit r/SideProject",
        title="I built a privacy-first birthday/anniversary reminder app with WhatsApp/LINE/SMS drafts",
        body=textwrap.dedent(
            f"""
            I built {APP_NAME}, a small privacy-first occasion reminder app because I kept remembering birthdays too late or sending generic messages.

            What it does:
            - no login
            - no server/database
            - no analytics or contact upload
            - import CSV/JSON occasions
            - export calendar reminders
            - prepare editable WhatsApp, LINE, SMS, or share-sheet drafts

            Web Lite demo: {APP_URL}

            I am validating whether this is a real problem beyond me before spending money on app-store distribution or backend hosting. Would you use something like this, or is calendar plus manual WhatsApp already enough?
            """
        ).strip(),
        url="https://www.reddit.com/r/SideProject/submit",
    ),
    "reddit_productivity": LaunchDraft(
        channel="Reddit r/productivity",
        title="Looking for feedback: privacy-first occasion reminders without uploading contacts",
        body=textwrap.dedent(
            f"""
            I am testing a small tool for remembering birthdays, anniversaries, and personal occasions without uploading contacts or creating an account.

            The flow is intentionally simple:
            1. Add or import occasions.
            2. Export calendar reminders.
            3. When reminded, open a prepared WhatsApp/LINE/SMS draft and press Send yourself.

            Demo: {APP_URL}

            I would love feedback on whether this reduces friction or whether calendar reminders alone are enough.
            """
        ).strip(),
        url="https://www.reddit.com/r/productivity/submit",
    ),
    "indiehackers": LaunchDraft(
        channel="Indie Hackers",
        title="Validating a privacy-first occasion reminder app before spending on stores/backend",
        body=textwrap.dedent(
            f"""
            I built a login-free Web Lite app called {APP_NAME} to validate a simple problem: people remember important occasions too late, or they remember but do not follow through with a thoughtful message.

            Current version:
            - local-only browser data
            - CSV/JSON import and backup
            - calendar export for reminders
            - WhatsApp, LINE, SMS, and share-sheet draft handoff
            - no contact upload, analytics, ads, or server

            Demo: {APP_URL}

            I am considering a native Android app first because local notifications are much smoother than web/calendar import. What would you validate before paying for store distribution or backend hosting?
            """
        ).strip(),
        url="https://www.indiehackers.com/post/new",
    ),
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Prepare TinyTools launch posts without storing credentials.")
    parser.add_argument("--channel", choices=[*DRAFTS.keys(), "all"], default="all")
    parser.add_argument("--open", action="store_true", help="Open composer pages where the platform supports it.")
    parser.add_argument("--markdown", default="", help="Write a portable launch checklist markdown file.")
    parser.add_argument("--mark-posted", choices=DRAFTS.keys(), help="Append a posted marker for a channel.")
    args = parser.parse_args()

    OUTBOX.mkdir(exist_ok=True)

    if args.mark_posted:
        _mark_posted(DRAFTS[args.mark_posted])
        print(f"Marked posted: {DRAFTS[args.mark_posted].channel}")
        return

    selected = DRAFTS.values() if args.channel == "all" else [DRAFTS[args.channel]]
    for draft in selected:
        _write_draft(draft)
        print("\n" + "=" * 80)
        print(f"{draft.channel}: {draft.title}")
        print("-" * 80)
        print(draft.body)
        if args.open:
            _open_draft(draft)
    if args.markdown:
        _write_markdown(selected, Path(args.markdown))

    print(f"\nDrafts written to {OUTBOX.resolve()}")


def _write_draft(draft: LaunchDraft) -> None:
    filename = draft.channel.lower().replace(" ", "_").replace("/", "_") + ".txt"
    (OUTBOX / filename).write_text(f"{draft.title}\n\n{draft.body}\n", encoding="utf-8")


def _open_draft(draft: LaunchDraft) -> None:
    webbrowser.open(_composer_url(draft))


def _composer_url(draft: LaunchDraft) -> str:
    if draft.channel == "X":
        return f"{draft.url}?{urlencode({'text': draft.body})}"
    if draft.channel.startswith("Reddit"):
        return f"{draft.url}?{urlencode({'title': draft.title, 'text': draft.body})}"
    return draft.url


def _write_markdown(drafts, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# TinyTools launch checklist",
        "",
        "Open this issue from any laptop or mobile browser. The links below prepare drafts where the platform supports it, but you still review and press Post manually.",
        "",
    ]
    for draft in drafts:
        lines.extend(
            [
                f"## {draft.channel}",
                "",
                f"- [ ] Posted",
                f"- Composer: {_composer_url(draft)}",
                "",
                f"**Title**",
                "",
                draft.title,
                "",
                "**Body**",
                "",
                draft.body,
                "",
            ]
        )
    path.write_text("\n".join(lines), encoding="utf-8")


def _mark_posted(draft: LaunchDraft) -> None:
    write_header = not TRACKER.exists()
    with TRACKER.open("a", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["posted_at", "channel", "title", "url"])
        if write_header:
            writer.writeheader()
        writer.writerow(
            {
                "posted_at": datetime.now(UTC).isoformat(),
                "channel": draft.channel,
                "title": draft.title,
                "url": draft.url,
            }
        )


if __name__ == "__main__":
    main()
