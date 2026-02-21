import test from "node:test";
import assert from "node:assert/strict";
import { parseAndValidateTranslationPayload } from "./translate";

test("parseAndValidateTranslationPayload accepts valid payload", () => {
  const output = parseAndValidateTranslationPayload(
    JSON.stringify({ jp: "こんにちは", en: "Hello" })
  );

  assert.equal(output.jp, "こんにちは");
  assert.equal(output.en, "Hello");
});

test("parseAndValidateTranslationPayload rejects malformed JSON", () => {
  assert.throws(
    () => parseAndValidateTranslationPayload("{"),
    /invalid JSON/i
  );
});

test("parseAndValidateTranslationPayload rejects missing fields", () => {
  assert.throws(
    () =>
      parseAndValidateTranslationPayload(JSON.stringify({ jp: "こんにちは" })),
    /missing string field: en/i
  );
});

test("parseAndValidateTranslationPayload rejects empty values", () => {
  assert.throws(
    () =>
      parseAndValidateTranslationPayload(JSON.stringify({ jp: "  ", en: "" })),
    /must be non-empty strings/i
  );
});
