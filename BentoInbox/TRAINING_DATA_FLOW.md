# Training Data Flow & ML Model Explanation

## How Training Works

**Training happens naturally while you work!** Every time you categorize an email in the reading pane, you're creating training data for your future ML model.

No separate training screen needed - just use the inbox normally and categorize as you go.

## Where Your Training Data Is Saved

When you categorize an email, **two things** happen:

### 1. The Message Gets Categorized
```swift
message.userCategoryId = category.id
```
This sets the category on the `Message` object in SwiftData. This is what you see in the Inbox when you filter by category.

### 2. A Training Example Is Created
```swift
let example = TrainingExample(
    messageId: message.id, 
    categoryId: category.id, 
    source: "user"
)
modelContext.insert(example)
```

This creates a `TrainingExample` record that tracks:
- **Which email** you categorized (messageId)
- **Which category** you chose (categoryId)
- **When** you did it (createdAt - automatic)
- **Who/how** it was categorized (source: "user")

## Where Is This Data?

All of this is stored in your **SwiftData database** (local SQLite database on your Mac):

```
~/Library/Containers/[YourAppBundleID]/Data/Library/Application Support/
```

You can think of it like this:

### Messages Table
| id | from | subject | userCategoryId |
|----|------|---------|---------------|
| msg1 | sender@example.com | Newsletter | p3-uuid |
| msg2 | boss@work.com | Urgent | p1-uuid |

### TrainingExamples Table
| id | messageId | categoryId | createdAt | source |
|----|-----------|------------|-----------|--------|
| ex1 | msg1 | p3-uuid | 2024-11-16 | user |
| ex2 | msg2 | p1-uuid | 2024-11-16 | user |

## When Does ML Training Happen?

**Currently: It doesn't yet!** 

Right now you're just **collecting training data**. The actual ML model training will happen later when we:

1. Build a CoreML model training pipeline
2. Export your TrainingExamples
3. Use Apple's CreateML or a custom training script

## The Full Training Pipeline (To Be Built)

### Phase 1: Data Collection (✅ YOU ARE HERE)
- Manually categorize 100+ emails
- TrainingExamples accumulate in database
- Each example is a labeled data point

### Phase 2: Feature Extraction (Not built yet)
Extract features from emails:
- Sender domain
- Subject keywords
- Email length
- Time of day
- Thread depth
- Presence of attachments

### Phase 3: Model Training (Not built yet)
Use CreateML to train model:
```swift
// Pseudocode for later
let trainingData = extractFeatures(from: trainingExamples)
let model = try MLTextClassifier(trainingData: trainingData)
model.write(to: "EmailClassifier.mlmodel")
```

### Phase 4: Model Deployment (Not built yet)
- Load trained CoreML model
- Run predictions on new emails
- Store predictions in `message.predictedCategoryId`

### Phase 5: Hybrid System (Not built yet)
- CoreML predicts category
- If confidence < threshold, use LLM
- Show both predictions to user
- User corrections improve model

## Why Collect Data First?

**You need labeled examples before you can train!**

Machine learning models learn by example:
- **Input**: Email features (sender, subject, content)
- **Output**: Category (P1, P2, P3, or P4)

The more examples you provide, the better the model learns your preferences.

### Training Data Quality

| # of Examples | Model Quality |
|--------------|---------------|
| 0-50 | Not enough data |
| 50-100 | Basic model, ~60% accuracy |
| 100-200 | Good model, ~75% accuracy |
| 200-500 | Great model, ~85% accuracy |
| 500+ | Excellent model, ~90%+ accuracy |

## What Happens at 100 Examples?

When you reach 100 categorized emails:
1. You have enough data to train a basic model
2. We'll build the training pipeline (next step!)
3. The model will start making predictions
4. You can compare CoreML predictions vs LLM analysis

## Current Status: Data Collection Phase

**What you're doing now:**
- ✅ Collecting labeled training data **in the reading pane**
- ✅ Each categorization is saved to database
- ✅ Building up a dataset for ML training
- ✅ Use hotkeys (1-4) for fast categorization

**How to train:**
1. Open an email in the detail pane
2. Press **1**, **2**, **3**, or **4** to categorize (or use the picker)
3. Training example is saved automatically
4. Move to next email
5. Repeat until you reach 100+ emails

**What's next:**
1. Categorize more emails (get to 100+)
2. Build CoreML training pipeline
3. Train first model
4. Add prediction functionality
5. Compare CoreML vs LLM

## How to Check Your Training Progress

You can query the database to see how many examples you have:

```swift
let descriptor = FetchDescriptor<TrainingExample>()
let examples = try modelContext.fetch(descriptor)
print("You've categorized \(examples.count) emails!")
```

Or by category:
```swift
let p1Examples = examples.filter { $0.categoryId == p1UUID }
print("P1 examples: \(p1Examples.count)")
```

## Why TrainingExamples Are Separate from Messages

**Message.userCategoryId** = The current category (can change)
**TrainingExample** = Historical record (never changes)

This separation is important because:
- You might recategorize an email
- You want to track the history of decisions
- Training data should be immutable
- You can track model improvements over time

## Next Development Steps

1. **Add training progress indicator**
   - Show "X/100 trained" in UI
   - Celebration at milestones
   
2. **Build feature extraction**
   - Parse email into ML features
   - Create MLDataTable
   
3. **Integrate CreateML**
   - Train text classifier
   - Export .mlmodel file
   
4. **Add prediction**
   - Load model
   - Predict on new emails
   - Store in predictedCategoryId
   
5. **Build hybrid system**
   - CoreML for fast predictions
   - LLM for uncertain cases
   - Show both results

6. **Add retraining**
   - Periodic retraining
   - Active learning (prioritize uncertain emails)
   - Continuous improvement

## Summary

**Right now:**
- You're manually labeling emails
- Data is saved in SwiftData as TrainingExamples
- No ML model exists yet

**After 100 examples:**
- We'll build the training pipeline
- Create your first ML model
- Start getting automated predictions

**The goal:**
- Train a personalized model that learns YOUR email priorities
- Compare it against LLM predictions
- Achieve fast, accurate, on-device email categorization

Keep categorizing! Each email you label makes the future model smarter. 🚀
