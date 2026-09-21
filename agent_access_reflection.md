# Agent Data Access Reflection

## 1. What Worked Well

Exposing dbt models through MCP worked smoothly. The clear model and column descriptions gave the agent enough context to understand the structure and relationships. The agent was able to navigate across the schemas, interpret how models connected, and ask meaningful questions about capabilities and dependencies. The AI was really fast at understanding the data. When dbt models are effecivly documented, this makes working with AI much easier.

---

## 2. What Was Difficult or Confusing

The model seemed to work on the first try with my descriptions. If I were to fully integrate an AI agent into the project using the MCP I imagine I would find a lot more accuracy errors. How well the agent understands the business context of the project partially depends on the descriptions but also the prompt I give the AI. The AI only works as good as the data and descriptions that you give it.

---

## 3. Documentation Quality

To make the descriptions more agent friendly I had each model description explain the business entity it represents, what grain it has, and how it relates to other models. I also included the business meaning in each of the column names rather than just describing what the column is. I also clarified key columns and how they were used (joings, foreign keys, primary keys). For date time columns I specified the timezone and what the timestamps represent. For calculated columns I described the calculation logic behind them.

---

## 4. Production Considerations

If I were to implement an MCP server in a real company, I would prioritize handling sensitive information such as personally identifiable information (PII) and financial data. Another important consideration is bias in AI systems. I would avoid including attributes like race or gender in the data used by the AI to reduce the risk of biased outcomes.

I would also implement access controls for different parts of the data. For example, the finance team would have different access privileges than the marketing team. I would follow the principle of least privilege when assigning user roles.

To audit the AI, I would have data professionals periodically review and fact-check its responses to ensure it does not hallucinate or drift off course. If the AI were to generate an inaccurate SQL query, I would prioritize updating the MCP so the agent produces correct queries.

To address data freshness, I would ensure that tables include timestamps indicating when the data was created. Understanding the current data and clearly defining how much data is needed for accurate results would help improve the AI’s performance.

To manage costs, I would set up usage and cost alerts for the AI. If users consistently exceed their limits, I would restrict their usage. However, if there is a strong business case for increasing the AI budget, those usage limits could be expanded.

---

## 5. Business Use Cases

One business case for this MCP would be enabling business executives to ask ad hoc questions about company data, such as sales, inventory, or other related metrics. This would differ from a traditional dashboard because it could handle highly specific questions that a dashboard may not be designed to support. For example, an executive could ask, “How have sales in Japan trended over the past six months, and what percentage have they increased or decreased?” Rather than needing to ask a data analyst to write a query, the business executive could interact directly with the AI.

Another use case would be allowing customers to ask questions about their own purchasing data. The MCP’s view would be restricted to their individual information. They could ask questions such as, “How much have I spent over the past four months?” or “What are my projected expenses for the next two weeks?” This would be especially useful for customers who manage oversee organizational spending. 

---

## 6. The Bigger Picture

Data engineering roles will evolve with the integration of AI into their workflows. Data engineers will still be responsible for ensuring the efficient flow, transformation, and storage of data, as they have always done. However, because AI systems do not inherently understand business context or intended use cases, data engineers will also need to provide clear definitions, metadata, and documentation to help AI interpret data correctly. They will need a stronger understanding of the business meaning behind the data and will work closely with software engineers to ensure that data ingestion and streaming pipelines are compatible with AI-driven use cases.

Overall, this represents more of an expansion of the role than a complete replacement. A major shift will be moving from primarily “dashboard-friendly” data models—optimized for fixed reports and metrics—to “agent-friendly” models that support flexible, natural language queries. This requires richer context, clearer relationships between data entities, and more explicit business logic so AI systems can reliably generate accurate insights.
