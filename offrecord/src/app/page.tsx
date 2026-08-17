"use client";

/**
 * TEMPORARY — theme & component preview.
 *
 * This page exists so the look of the two themes can be signed off before the
 * seven real screens are ported. It is deleted once the feed lands at `/`.
 */

import { useState } from "react";
import {
  ChatCircleIcon,
  DotsThreeIcon,
  HeartIcon,
  PlusCircleIcon,
} from "@phosphor-icons/react";
import { ThemeToggle } from "@/components/ThemeToggle";
import { CATEGORIES } from "@/lib/categories";

export default function PreviewPage() {
  const [activeChip, setActiveChip] = useState("all");
  const [sort, setSort] = useState("trending");
  const [reacted, setReacted] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);

  return (
    <main
      style={{
        maxWidth: "var(--feed-max)",
        margin: "0 auto",
        padding: "var(--space-6) var(--space-5) var(--space-10)",
        display: "flex",
        flexDirection: "column",
        gap: "var(--space-8)",
      }}
    >
      <header
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: "var(--space-4)",
        }}
      >
        <div>
          <h4 style={{ margin: 0 }}>OffRecord</h4>
          <p className="text-faint" style={{ margin: 0, fontSize: 13 }}>
            Theme preview — not a real screen
          </p>
        </div>
        <ThemeToggle />
      </header>

      {/* — feed controls — */}
      <section style={{ display: "flex", flexDirection: "column", gap: "var(--space-4)" }}>
        <div className="seg" style={{ alignSelf: "flex-start" }}>
          {["trending", "latest", "discussed"].map((mode) => (
            <label className="seg-opt" key={mode}>
              <input
                type="radio"
                name="sort"
                checked={sort === mode}
                onChange={() => setSort(mode)}
              />
              {mode[0].toUpperCase() + mode.slice(1)}
            </label>
          ))}
        </div>

        <div
          style={{
            display: "flex",
            gap: "var(--space-2)",
            overflowX: "auto",
            paddingBottom: 2,
            // Hides the scrollbar track on desktop without breaking the swipe.
            scrollbarWidth: "none",
          }}
        >
          {[{ id: "all", label: "All" }, ...CATEGORIES].map((cat) => (
            <button
              key={cat.id}
              type="button"
              className="chip"
              aria-pressed={activeChip === cat.id}
              onClick={() => setActiveChip(cat.id)}
            >
              {cat.label}
            </button>
          ))}
        </div>
      </section>

      {/* — a real post card — */}
      <section style={{ display: "flex", flexDirection: "column", gap: "var(--space-4)" }}>
        <h6 style={{ margin: 0 }}>Post card</h6>

        <article className="card elev-sm">
          <div style={{ display: "flex", alignItems: "center", gap: "var(--space-3)" }}>
            <span className="tag tag-accent">Confession</span>
            <span style={{ flex: 1 }} />
            <span className="text-faint" style={{ fontSize: 12 }}>
              3h ago
            </span>
            <button type="button" className="btn btn-icon" aria-label="More options">
              <DotsThreeIcon size={20} />
            </button>
          </div>

          <div className="text-muted" style={{ fontSize: 13 }}>
            midnightoodle
          </div>

          <p style={{ margin: 0, fontSize: 15.5, lineHeight: 1.6 }}>
            I ate an entire pizza alone in the library during finals week and made
            zero eye contact with anyone. No regrets.
          </p>

          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: "var(--space-5)",
              marginTop: "var(--space-1)",
            }}
          >
            <button
              type="button"
              className="btn btn-ghost btn-sm"
              onClick={() => setReacted((r) => !r)}
              style={{ color: reacted ? "var(--color-accent)" : undefined }}
              aria-pressed={reacted}
            >
              <HeartIcon size={18} weight={reacted ? "fill" : "regular"} />
              {reacted ? 129 : 128}
            </button>
            <button type="button" className="btn btn-ghost btn-sm">
              <ChatCircleIcon size={18} />
              24
            </button>
          </div>
        </article>

        {/* loading state */}
        <div className="card" style={{ gap: "var(--space-3)" }}>
          <div className="skeleton" style={{ width: "35%" }} />
          <div className="skeleton" style={{ width: "95%" }} />
          <div className="skeleton" style={{ width: "60%" }} />
        </div>
      </section>

      {/* — controls — */}
      <section style={{ display: "flex", flexDirection: "column", gap: "var(--space-4)" }}>
        <h6 style={{ margin: 0 }}>Controls</h6>
        <div style={{ display: "flex", gap: "var(--space-3)", flexWrap: "wrap" }}>
          <button type="button" className="btn btn-primary">
            <PlusCircleIcon size={18} />
            New post
          </button>
          <button type="button" className="btn btn-secondary">Secondary</button>
          <button type="button" className="btn btn-ghost">Ghost</button>
          <button type="button" className="btn btn-danger" onClick={() => setDialogOpen(true)}>
            Open dialog
          </button>
          <button type="button" className="btn btn-primary" disabled>
            Disabled
          </button>
        </div>

        <div className="field">
          <label htmlFor="preview-input">Invite code</label>
          <input id="preview-input" className="input" placeholder="e.g. OFFR-XXXX" />
        </div>

        <div className="field">
          <label htmlFor="preview-textarea">What&apos;s on your mind?</label>
          <textarea
            id="preview-textarea"
            className="input"
            placeholder="Share a confession, ask a question, vent a little..."
          />
        </div>

        <div style={{ display: "flex", gap: "var(--space-2)", flexWrap: "wrap" }}>
          <span className="tag tag-accent">Accent</span>
          <span className="tag tag-neutral">Neutral</span>
          <span className="tag tag-outline">Pending review</span>
          <span className="tag tag-danger">Removed</span>
        </div>
      </section>

      {dialogOpen && (
        <div
          className="dialog-backdrop"
          role="dialog"
          aria-modal="true"
          aria-labelledby="preview-dialog-title"
          onClick={() => setDialogOpen(false)}
        >
          <div className="dialog fade-in" onClick={(e) => e.stopPropagation()}>
            <div className="dialog-title" id="preview-dialog-title">
              Report this post
            </div>
            <div className="dialog-body">
              Your report is anonymous. Choose the reason that fits best.
            </div>
            {["Harassment", "Spam", "Personal information", "Threatening content", "Other"].map(
              (reason) => (
                <label className="radio" key={reason}>
                  <input type="radio" name="reason" />
                  <span className="dot" />
                  {reason}
                </label>
              ),
            )}
            <div className="dialog-actions">
              <button type="button" className="btn btn-secondary" onClick={() => setDialogOpen(false)}>
                Cancel
              </button>
              <button type="button" className="btn btn-primary">
                Submit report
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
