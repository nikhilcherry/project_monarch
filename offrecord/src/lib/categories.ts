/**
 * The V1 category set. These are stable identifiers — the `id` is what gets
 * written to the database, the `label` is what a user sees. Renaming a label
 * later must never change an id, or existing posts lose their category.
 */
export const CATEGORIES = [
  { id: "confession", label: "Confession" },
  { id: "question", label: "Question" },
  { id: "rant", label: "Rant" },
  { id: "funny", label: "Funny" },
  { id: "advice", label: "Advice" },
  { id: "other", label: "Other" },
] as const;

export type CategoryId = (typeof CATEGORIES)[number]["id"];

export const CATEGORY_LABELS: Record<CategoryId, string> = Object.fromEntries(
  CATEGORIES.map((c) => [c.id, c.label]),
) as Record<CategoryId, string>;
