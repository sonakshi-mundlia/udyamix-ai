# Udyamix AI

**AI-powered business management and decision-support platform for small and medium-sized businesses (SMEs).**

Udyamix AI combines **business data, analytics, RAG, and LLM-powered insights** to help businesses understand their operations and make better decisions from their actual data.

Instead of being only a chatbot or dashboard, Udyamix connects business records with an AI assistant that can analyze data, retrieve relevant business knowledge, validate results, and provide actionable recommendations.

---

## Key Features

### Business Dashboard

* Sales and expense tracking
* Daily, weekly, monthly and overall analytics
* Business performance trends
* Revenue and expense summaries
* Data-driven dashboard insights

### AI Business Assistant

A conversational assistant that can answer business-related questions using the user's actual business data and stored knowledge.

Examples:

> "Why did my expenses increase this month?"

> "How are my sales performing?"

> "What can I do to improve my profit?"

> "What are the main reasons for my declining revenue?"

The assistant is designed to provide **business-specific answers rather than generic LLM responses**.

### RAG-Based Knowledge System

Udyamix uses **Retrieval-Augmented Generation (RAG)** to give the LLM relevant business knowledge before generating an answer.

The pipeline is:

```text
Business Documents
       ↓
Document Processing
       ↓
Text Chunking
       ↓
Embeddings
       ↓
PostgreSQL + Vector Search
       ↓
Relevant Context
       ↓
LLM
       ↓
Business Insight
```

This reduces reliance on the model's general knowledge and allows responses to be grounded in the application's business information.

### Business Data Validation

A major focus of Udyamix is **not blindly trusting LLM output**.

Business values are validated against backend data before being presented as insights.

For example:

```text
Database:
Sales = ₹50,000
Expenses = ₹30,000

        ↓

Backend calculation

Profit = ₹20,000

        ↓

LLM explains the result
```

The LLM is therefore used primarily for **reasoning, explanation and recommendations**, while important numerical values can come from trusted backend calculations.

### AI Insights

The AI insight system can generate structured information such as:

* Title
* Summary
* Important metric
* Urgency
* Root cause
* Business impact
* Formula/calculation
* Recommendations

This makes AI responses more useful than simple text generation.

---

## What Makes Udyamix Different?

Traditional business applications usually provide:

```text
Business Data → Dashboard → User
```

Generic AI applications provide:

```text
Question → LLM → Answer
```

Udyamix combines both:

```text
                ┌──────────────┐
                │ Business DB  │
                └──────┬───────┘
                       ↓
                ┌──────────────┐
                │ Analytics &  │
                │ Validation   │
                └──────┬───────┘
                       ↓
User → AI Assistant → RAG → LLM
                       ↓
              Validated Insight
                       ↓
                Recommendation
```

### Key improvements

* **Grounded AI instead of generic AI**
* **Backend-validated business metrics**
* **RAG for business knowledge**
* **Structured AI insights**
* **Separation of calculations from LLM reasoning**
* **Vector search using PostgreSQL**
* **Designed around real SME business workflows**

---

## Architecture

```text
┌───────────────────────────────┐
│        Flutter Client         │
│                               │
│ Dashboard | Business Data     │
│ AI Assistant | Insights       │
└───────────────┬───────────────┘
                │ REST API
                ↓
┌───────────────────────────────┐
│          FastAPI              │
│          Backend              │
│                               │
│ Authentication                │
│ Business APIs                 │
│ Analytics                     │
│ Validation                    │
│ AI Insights                   │
└───────┬───────────┬───────────┘
        │           │
        ↓           ↓
┌────────────┐   ┌────────────────┐
│ PostgreSQL │   │ RAG Pipeline    │
│            │   │                │
│ Users      │   │ Chunking       │
│ Businesses │   │ Embeddings     │
│ Sales      │   │ Retrieval      │
│ Expenses   │   │ Vector Search  │
└────────────┘   └───────┬────────┘
                         ↓
                  ┌──────────────┐
                  │     LLM      │
                  │ OpenRouter   │
                  └──────────────┘
```

---

## AI / RAG Architecture

Udyamix uses a retrieval pipeline based on semantic similarity.

### Embedding

Business documents are converted into vector representations using an embedding model such as:

```text
all-MiniLM-L6-v2
```

### Vector Storage

Embeddings are stored in **PostgreSQL with vector search support**.

### Retrieval

When the user asks a question:

```text
User Question
      ↓
Question Embedding
      ↓
Similarity Search
      ↓
Top-K Relevant Chunks
      ↓
Context + Question
      ↓
LLM
```

The retrieved context helps the LLM generate answers based on relevant business information.

---

## Reliable AI Design

Udyamix follows an important principle:

> **The LLM should not be the source of truth for business numbers.**

For example, instead of allowing the LLM to calculate revenue or profit independently:

```text
Database
   ↓
Backend
   ↓
Verified calculation
   ↓
LLM explanation
   ↓
User
```

This helps reduce issues such as:

* Hallucinated numbers
* Incorrect calculations
* Unsupported business claims
* Generic recommendations

The backend remains responsible for **data integrity and calculations**, while the LLM focuses on **natural-language reasoning and recommendations**.

---

## Tech Stack

### Frontend

* Flutter
* Dart

### Backend

* Python
* FastAPI
* Pydantic

### Database

* PostgreSQL
* Vector similarity search

### AI

* Large Language Model via OpenRouter
* Sentence Transformers
* RAG
* Embeddings

### Development

* Git
* GitHub
* REST APIs

---

## Running Locally

### 1. Clone the repository

```bash
git clone https://github.com/sonakshi-mundlia/udyamix-ai.git

cd udyamix-ai
```

### 2. Setup backend

```bash
cd backend

python -m venv venv
```

Activate the environment.

**Windows:**

```bash
venv\Scripts\activate
```

**Linux/macOS:**

```bash
source venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Configure your `.env` file and database.

### 3. Start FastAPI

```bash
uvicorn app.main:app --reload
```

The API will be available locally through the FastAPI server.

### 4. Run Flutter

From the Flutter project:

```bash
flutter pub get
flutter run
```

Configure the API base URL in the Flutter application to point to your backend.

---

## Example AI Flow

```text
User:
"Why is my profit lower this month?"

             ↓

FastAPI
             ↓
Retrieve business metrics
             ↓
Validate sales & expenses
             ↓
Retrieve relevant business knowledge
             ↓
RAG Context
             ↓
LLM
             ↓
Structured AI Insight
             ↓

Root Cause
Impact
Metric
Recommendation
```

---

## Project Goal

Udyamix aims to make business intelligence more accessible to SMEs by combining:

**Business Management + Analytics + RAG + LLM + Data Validation**

The goal is not simply to build another AI chatbot, but to build an AI system that can **understand business context, work with real business data, and turn that data into useful decisions.**

---

## Future Improvements

* Advanced business forecasting
* Automated financial reports
* More powerful agentic workflows
* Multi-business knowledge management
* Improved recommendation systems
* Predictive analytics
* Role-based business intelligence
* Scalable production infrastructure

---

