# CSV Export & Model Comparison Guide

## Quick Start

### Step 1: Export Your First Batch

1. Open BentoInbox
2. Click the **"Export Analysis"** button in the toolbar
3. Select **"Comparison (for manual annotation)"**
4. Set number of emails to **20**
5. Click **"Export CSV"**
6. File will be saved to your Desktop as `email_analysis_comparison_YYYY-MM-DD.csv`

### Step 2: Open in Spreadsheet

Open the CSV in Excel, Numbers, or Google Sheets. You'll see these columns:

| Column | Description | Your Task |
|--------|-------------|-----------|
| **Message ID** | Unique email ID | (Read only) |
| **Sender** | Email sender | (Read only) |
| **Subject** | Email subject | (Read only) |
| **AI Tags** | Tags the AI assigned | (Read only) |
| **Expected Tags (Manual)** | WHAT TAGS SHOULD BE | ← Fill this in! |
| **False Positives** | Tags AI added incorrectly | ← Calculate this |
| **False Negatives** | Tags AI missed | ← Calculate this |
| **Notes** | Any observations | Optional |

### Step 3: Manually Annotate

For each email row, fill in the **"Expected Tags (Manual)"** column with what the tags SHOULD be.

**Example:**

```
Row 1:
- Sender: Krishna Vasamshetti <recruiter@mitchell-martin.com>
- Subject: Senior Python Developer - Jersey City
- AI Tags: general
- Expected Tags: recruiting; cold-outreach  ← You fill this in
- False Positives: general  ← AI said "general" but shouldn't have
- False Negatives: recruiting; cold-outreach  ← AI missed these
```

**Tip**: Use semicolons (`;`) to separate multiple tags.

### Step 4: Calculate False Positives & Negatives

For each row:

1. **False Positives** = Tags in "AI Tags" but NOT in "Expected Tags"
2. **False Negatives** = Tags in "Expected Tags" but NOT in "AI Tags"

**Example 2:**

```
Row 2:
- AI Tags: newsletter; personal-sender
- Expected Tags: newsletter
- False Positives: personal-sender  ← AI wrongly added this
- False Negatives: (none)  ← AI didn't miss any tags
```

### Step 5: Calculate Overall Accuracy

At the bottom of your spreadsheet, count:

```
Total emails: 20

Count for each tag:
- True Positives (TP): AI correctly identified the tag = 45
- False Positives (FP): AI incorrectly added the tag = 12
- False Negatives (FN): AI missed the tag = 8

Precision = TP / (TP + FP) = 45 / (45 + 12) = 78.9%
Recall = TP / (TP + FN) = 45 / (45 + 8) = 84.9%
F1 Score = 2 × (P × R) / (P + R) = 81.8%
```

**Interpretation**:
- **Precision** = How many AI tags were correct?
- **Recall** = How many correct tags did AI find?
- **F1 Score** = Overall accuracy (balance of precision & recall)

---

## Comparing Multiple Models

### Step 1: Test with Current Model (Baseline)

1. Export CSV with current model (`llama3.1:8b`)
2. Rename file to `baseline_llama3.1.csv`
3. Manually annotate (fill in Expected Tags)
4. Calculate accuracy metrics

### Step 2: Switch Models in Ollama

```bash
# Pull a different model
ollama pull mistral:7b

# Or try other models:
ollama pull phi3:mini
ollama pull gemma2:9b
ollama pull qwen2.5:7b
```

### Step 3: Re-analyze with New Model

**IMPORTANT**: You need to re-analyze the SAME emails with the new model.

Option A: Delete `EmailAnalysis` and `EmailTag` records in your database, then refresh emails.

Option B: Use a separate test database for each model.

### Step 4: Export Again

1. Switch to new model in app settings (if you have model selector)
2. Export CSV again
3. Rename to `test_mistral7b.csv`
4. Copy "Expected Tags" column from baseline CSV (don't re-annotate!)
5. Calculate False Positives/Negatives for new model

### Step 5: Compare Results

Create a comparison table:

| Model | Precision | Recall | F1 Score | Speed (avg) | Notes |
|-------|-----------|--------|----------|-------------|-------|
| llama3.1:8b | 78.9% | 84.9% | 81.8% | 2.3s | Baseline |
| mistral:7b | 82.1% | 80.5% | 81.3% | 1.8s | Faster, similar accuracy |
| phi3:mini | 75.2% | 79.8% | 77.4% | 0.9s | Fast but less accurate |
| gemma2:9b | 85.4% | 86.2% | 85.8% | 3.1s | Best accuracy, slower |

---

## Tag-Specific Analysis

Some tags may be more accurate than others. Break down by tag:

| Tag | Precision | Recall | F1 | Common Errors |
|-----|-----------|--------|----|---------------|
| personal-sender | 65% | 70% | 67% | Confuses recruiters with personal |
| recruiting | 90% | 85% | 87% | Sometimes misses subtle job offers |
| newsletter | 95% | 92% | 93% | Very accurate |
| spam-likely | 80% | 60% | 69% | Misses subtle scams |
| meeting | 85% | 88% | 86% | Pretty good |

**Insight**: Focus improvements on low-scoring tags (e.g., "personal-sender", "spam-likely").

---

## Quick Wins Already Implemented

✅ You already have these improvements in your code:

1. **Temperature lowered to 0.1** (from 0.3)
   - More consistent, deterministic results
   
2. **Few-shot examples added to prompt**
   - 8 real-world examples to guide the LLM
   
3. **Tag validation rules**
   - Removes conflicting tags (e.g., "newsletter" + "personal-sender")
   - Enforces tag hierarchy
   
**Expected improvement**: ~65% → ~80% accuracy

---

## Next Steps After Initial Evaluation

Based on your CSV analysis results:

### If accuracy is < 75%:
1. Check if prompt examples match your email types
2. Try a larger model (e.g., `llama3.1:70b` if you have resources)
3. Add more examples to few-shot prompt
4. Consider adding chain-of-thought reasoning

### If accuracy is 75-85%:
1. Identify problematic tags (low precision/recall)
2. Add specific examples for those tags
3. Refine tag definitions to be clearer
4. Add domain-based rules for obvious cases

### If accuracy is > 85%:
🎉 You're doing great! Focus on:
1. Edge cases (unusual emails)
2. Speed optimization
3. User experience improvements
4. Custom user rules

---

## Advanced: Per-Email Difficulty Rating

Add a "Difficulty" column to your CSV:

- **Easy**: Newsletter, receipts, obvious spam → AI should get 95%+ correct
- **Medium**: Meeting requests, work emails → AI should get 80%+ correct
- **Hard**: Ambiguous senders, unclear content → AI might get 60-70% correct

Calculate accuracy separately for each difficulty level to understand where the model struggles.

---

## Troubleshooting

### "Export failed" error
- Check that you have emails in your inbox
- Make sure SwiftData is working correctly
- Check console for detailed error messages

### CSV has missing data
- Some emails might not have been analyzed yet
- Run "Refresh" in the app to trigger analysis
- Check that LLM service is running (Ollama)

### Can't open CSV on Desktop
- File is saved to `~/Desktop/` on macOS
- On iOS, check the Files app → On My iPhone → Documents

### All AI tags are "general"
- Mock service might be running instead of Ollama
- Check that Ollama is running: `ollama list`
- Verify model is downloaded: `ollama pull llama3.1:8b`

---

## Example Evaluation Workflow

**Monday**: Export baseline with `llama3.1:8b`, manually annotate
**Tuesday**: Calculate metrics, identify problem tags
**Wednesday**: Implement improvements (add examples, refine prompts)
**Thursday**: Re-export, compare metrics
**Friday**: Test different model (`mistral:7b`), compare

**Goal**: Achieve 85%+ F1 score by end of week 🎯

---

## Templates

### Simple Accuracy Calculator (Spreadsheet Formula)

In Google Sheets/Excel, add these formulas at the bottom:

```excel
=COUNTIF(E2:E21, "<>")  # Count rows with Expected Tags
=COUNTIF(F2:F21, "")    # Count rows with no False Positives (perfect)
=COUNTIF(G2:G21, "")    # Count rows with no False Negatives (perfect)

Accuracy = (Perfect Rows / Total Rows) × 100%
```

### Tag Frequency Counter

```excel
=COUNTIF(D2:D21, "*recruiting*")  # How many times "recruiting" appears
```

---

## Resources

- **Full guide**: See `IMPROVING_AI_TAG_ACCURACY.md` for all strategies
- **Code**: See `ImprovedTagging.swift` for validation rules
- **Export code**: See `EmailAnalysisExporter.swift` for CSV generation

---

Good luck with your evaluation! 🚀
