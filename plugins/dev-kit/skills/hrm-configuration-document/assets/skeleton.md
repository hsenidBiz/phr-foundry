---
feature_id: {{WorkItemID}}
title: {{Feature Title in Title Case}}
module: {{Module Name}}
release: {{26R1}}
release_version: {{10.3000.0}}
doc_version: 1.0.0
tier: {{T1|T2|T3}}
---

<!-- Copy this file to <Release>-<ID>-<Module>-<Short Title>-Doc.md.
     Delete every section whose inclusion rule (references/template-outline.md) is false.
     Delete all {{...}} and all comments before building. Headings stay unnumbered. -->

<!-- INCLUDE rules (T1/T2/T3): Introduction M/M/M · Scope table T2+T3 (T1: one sentence) · Intended Audience T3 ·
     Definitions when terms are used · Feature Overview M · Prerequisites when dependencies stated ·
     Configuration Parameters M · Parameter cards T2+T3 · Configuration Procedure M · Security when stated ·
     System Behavior T2+T3 (T1 when not obvious) · Database Changes when stated · Integration when stated ·
     Validation T2 when tests given, T3 M · Troubleshooting/Limitations when stated (T3 M) ·
     Deployment, Implementation Checklist T3 · Error Catalogue when codes · Change Control M -->

# Introduction

## Purpose

This document describes how to configure {{feature}} in the {{Module}} module of PeoplesHR {{Release}} (Version {{x}}). It is intended for implementation, support and system administration teams.

## Scope

| In Scope | Out of Scope |
|---|---|
| {{item}} | {{item}} |

## Intended Audience

<!-- T3, or T2 when unusual -->

## Definitions and Acronyms

| Term | Definition |
|---|---|
| {{Term}} | {{Definition}} |

# Feature Overview

Previously, {{old behavior}}. With this change, {{new behavior}}.

**Key features:**

- {{Capability}}

# Prerequisites

| Component | What You Need |
|---|---|
| PeoplesHR release | {{26R1 (Version 10.3000.0) or later}} |

# Configuration Parameters

| Parameter Key | Data Type | Allowed Values | Default Value | Configuration Location | Description |
|---|---|---|---|---|---|
| `{{KEY}}` | {{Type}} | {{Values}} | {{Default}} | {{Location}} | {{Purpose}} |

## Configuration Parameter: {{Friendly Name}}

| Item | Specification |
|---|---|
| Parameter Name | `{{KEY}}` |
| Description | {{What it controls}} |
| Storage | `{{HS_CLIENT_APPSETTING}}` |
| Data Type | {{Type}} |
| Allowed Values | `1` – {{effect}}<br>`0` – {{effect}} |
| Default Value | {{Default}} |
| Dependencies | {{only if stated}} |
| Configuration Responsibility | {{Owner}} |

# Configuration Procedure

**Navigation Path:** **{{Full > Path > From > Notes}}**

**Configuration Tab:** **{{Tab}}**

**Search Parameter:** `{{KEY}}`

1. Log in to PeoplesHR as {{role}}.
2. Navigate to **{{Path}}**.
3. Select the **{{Tab}}** tab.
4. Search for `{{KEY}}`.
5. Set the value to `{{value}}` and click **Save**.

<!-- Only if the developer supplied it: -->
![Figure 1: {{Caption sentence.}}](images/{{file}}.png)

> **Important:** {{condition that changes the outcome}}

# Security and Access Setup

1. {{Step}}

# System Behavior

| `{{KEY_A}}` | `{{KEY_B}}` | Result |
|---|---|---|
| `0` | Any | {{Result}} |

# Database Changes

| Item | Specification |
|---|---|
| Table | `{{TABLE}}` |
| Change | {{Change}} |
| Deployment Script | `{{script.sql}}` |
| Script Location | {{Repository / delta folder}} |

# Integration and Data Formats

# Validation and Test Cases

| Test Case ID | Configuration | Action | Expected Result |
|---|---|---|---|
| TC-01 | `{{KEY}} = 0` | {{Action}} | {{Result}} |

# Troubleshooting

| Symptom | Likely Cause | Resolution |
|---|---|---|
| {{Symptom}} | {{Cause}} | {{Resolution}} |

# Limitations

- {{Limitation}}

# Deployment and Rollback

# Error Catalogue

# Implementation Checklist

| Step | Action | Owner |
|---|---|---|
| 1 | {{Action}} | {{Owner}} |

# Change Control

| Version | Date | Description | Author |
|---|---|---|---|
| 1.0.0 | {{DD/MM/YYYY}} | Initial document | {{Author}} |
