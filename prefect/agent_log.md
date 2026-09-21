# Agent Interaction Log: Prefect Flow

## 1. Setup

**Agent tool used:** Google Gemini Pro

**Why this tool?** I already had the agent installed in my Visual Studio terminal because of a 1 year free trial.
**Date:** Built on 4/9 and tested on 4/10

**Total time spent:** [Approximate hours/minutes]
I spent around 45 minutes making sure that everything was right in my PRD. Gemini took about 15 minutes to build everything out. Spent Another 10min to get it to work locally.
---

## 2. Initial Specification

_What did you give the agent to start with? Paste or summarize your initial prompt/instruction._

```
I told the agent to look at the prd.md file to see if it makes sense before it started coding. It read the file, but also used the mock_api.py as reference, so when it responded it cleary did not understand my instructions at first. After telling it to ignore that file and only base it's instructions on the prd it did it right first try.
```

**Did you share the PRD with the agent?** [Yes/No. If yes, how? Copy-paste, file reference, etc.]
Yes, I told it to reference the file.
---

## 3. Iteration Log

_Document the key back-and-forth iterations. You don't need to capture every message, but capture the important turning points._

### Iteration 1: [Brief description]
- **What I asked:** Inside of the prd.md file is a set of instructions to build out a prefect flow. Read these instructions and see if it makes sense. Do not start coding yet.
- **What the agent produced:** It repeated back to me what it understood, but it was all wrong because it was trying to reference the mock_api.py file as well which threw it off.
- **What worked:** It read the prd.
- **What didn't work:** It read the mock_api.py which it wasn't supposed to do
- **What I changed:** I told it to not base it's instructions on the mock_api.py

### Iteration 2: [Brief description]
- **What I asked:** Do not pull information from the mock_api.py. Only base the prefect flow from the prd.md. Repeate back to me that you understand this and then start building.
- **What the agent produced:** Agent built the flow successfully.
- **What worked:** Altered it's plan and successfully built the flow.
- **What didn't work:** Everything worked first try.
- **What I changed:** had to change \ to / to get it to work locally, but other than that it worked.


## 4. Final Result

**Did the agent-generated code work on first run?**
Yes, worked first try on docker, but I had to make one slight change to run it locally.
**If no, what broke?** 
Locally did not like the \ so I had to change them to /
**Percentage of final code written by the agent vs. you:**
- Agent wrote: 99%
- I wrote/modified: 1%

**Key files the agent created or modified:**
- [web_analytics_flow.py]: Built the flow successfully with a get_watermark, fetch_api_data, transform_data, and load_to_snowflake tasks.

---

## 5. What I Learned

### What the agent was good at:
- It was good at adapting based on my request and successfully building out the code when it had the right instructions.

### What the agent struggled with:
- It struggled with pulling informaiton from multiple files. Having everything in one prd.md file made the agent run faster. Traversing through files to look for things could mess it up or take a lot longer.

### What I would do differently next time:
- I think I spent too much time making the prd beforehand. I would start with smaller instructions and then talk with the agent back and forth before letting it go and build stuff.

### Time comparison estimate:
- **With agent:** 1.5 hours
- **Without agent (estimate):** By myself probably 3 hours. With regular ChatGPT probably around the same 1.5 hours.
- **Net impact:** About the same for this part of the assignment. Could have completed it just as fast pasting files back and forth from a chatbot. 

---

## 6. Reflection

_In 3-5 sentences, reflect on the experience of using an AI agent for development. What surprised you? What concerns you? How might this change the way you work in the future?_

Using the AI agent was a great experience. I learned about some of the limitations of agents such as not fully understanding the context of the system. Overall, the agent did an amazing job, but I had to do so much work on the prd, it would have almost been easier to just paste my instructions into a regular chatbot. On bigger project where there are not detailed homework instructions and there are multiple components I see how it would be extremely efficient to use agents in your workflows to build out code.
