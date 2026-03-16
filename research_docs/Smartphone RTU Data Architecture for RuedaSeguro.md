# **Data Architecture and Systems Integration for Real-Time Parametric Insurance: The RuedaSeguro Ecosystem**

The architectural transition of the motorcycle insurance industry in the mid-2020s represents a fundamental shift from traditional indemnity models to active, edge-based stabilization. In a socioeconomic environment like that of Venezuela, where urban logistics are sustained by a circulating park of motorcycles that is largely aged and where financial liquidity is constrained by inflationary pressures and fragmented banking, the role of the Data Architect is to create a high-integrity, resilient ecosystem that bridges the gap between physical events and financial settlement.1 RuedaSeguro’s mission is predicated on the Smart Liquidation System (SLI), a parametric model designed to provide stabilization payments within 15 minutes of a verified impact.1 To achieve this, the architecture must leverage the smartphone as a Remote Terminal Unit (RTU), implement a robust "Store and Forward" data lifecycle, and manage the delicate balance between on-chain immutability and off-chain data scalability through logical-to-physical mapping of blockchain metadata.1

## **Transforming the Smartphone into an Industrial Remote Terminal Unit**

The conceptualization of the smartphone as a Remote Terminal Unit (RTU) is the primary technical enabler for RuedaSeguro. Traditional telematics often rely on secondary hardware modules installed on the vehicle, which introduces significant onboarding friction and hardware costs that are prohibitive for the Venezuelan worker archetypes, "Carlos" and "Luis".1 By repurposing the ubiquitous smartphone as an RTU, the architecture leverages high-precision Micro-Electromechanical Systems (MEMS) sensors—specifically the tri-axial accelerometer and gyroscope—to catalog the position and motion of the rider in real-time.2

The accelerometer measures proper acceleration, capturing the body's motion in its own instantaneous rest frame, a distinction that is vital for distinguishing coordinate acceleration from the structural stress of an impact. This sensory input, while high-velocity and granular, is inherently noisy. To make the smartphone a reliable RTU, the Data Architect must design a telemetry pipeline that effectively filters noise while preserving the signature of a catastrophic event. This requires a sampling rate of at least 100 Hz to 200 Hz, as lower frequencies risk aliasing the transient peak of a collision, potentially missing the window where the acceleration magnitude reaches the critical trigger threshold.4

| Sensor Component | Physical Measurement | Role in RuedaSeguro Ecosystem |
| :---- | :---- | :---- |
| 3-Axis Accelerometer | Linear Acceleration (![][image1]) | Impact detection and vector magnitude calculation. |
| 3-Axis Gyroscope | Angular Velocity (Pitch, Yaw, Roll) | Behavioral analysis, lean angles, and accident confirmation. |
| GPS / GNSS | Geospatial Coordinates (![][image2]) | Geographic context, geofencing, and claims localization. |
| Magnetometer | Magnetic North orientation | Aiding dead reckoning and orientation stability. |

2

### **Mathematical Logic for Severe Impact Detection**

The core of the RTU’s intelligence resides in its ability to process raw sensor streams into actionable signals. The Data Architect must enforce the implementation of the vector magnitude calculation within the mobile application's edge layer.1 The magnitude ![][image3] is derived from the square root of the sum of the squares of the acceleration axes:

![][image4]  
In this implementation, ![][image5] represents the instantaneous values provided by the sensor fusion API, which typically combines raw accelerometer data with gravity-compensation algorithms to provide a clean linear acceleration vector.2 The architectural standard for a severe impact event is set at a threshold of 9G.1 This threshold is significantly higher than those used in standard automotive telematics—such as Progressive Snapshot’s "hard braking" trigger of approximately 7 mph per second—because the objective of RuedaSeguro is not merely underwriting but the detection of life-threatening trauma that necessitates immediate clinical liquidity.1

A 9G impact corresponds to a force level that, in most motorcycle dynamics, indicates a sudden stop against a fixed object or a violent high-side event. By establishing this high threshold, the architecture minimizes the risk of "false-positive settlement," where road hazards like deep potholes or high-speed navigation of speed bumps might otherwise trigger the Smart Liquidation System.1 The RTU logic must also incorporate a temporal sub-window analysis, typically looking at the three seconds of data surrounding the 9G peak, to distinguish between a dropped phone and a high-energy vehicle collision.4

### **Digital Filtering and Signal Conditioning**

To ensure the accuracy of the 9G trigger, raw telemetry must undergo digital signal processing (DSP) at the edge. Raw accelerometer data is often obscured by high-frequency vibration from the motorcycle's internal combustion engine and the static influence of gravity.2 The Data Architect mandates the use of a Butterworth filter, preferred for its maximally flat frequency response in the pass-band, which prevents the amplitude distortion of the impact signal.9

A multi-stage filtering approach is recommended. A high-pass Butterworth filter with a very low cutoff frequency (e.g., 0.1 Hz) is utilized to remove the DC component of gravity, which would otherwise bias the magnitude calculation by approximately 1G depending on the phone's orientation.8 Simultaneously, an eighth-order low-pass filter with a cutoff of 400 Hz can be employed to eliminate high-frequency motor noise and mains interference, focusing the signal analysis on the frequency band typical of human movement and vehicular impact.9 This ensures that the 9G threshold is met by the physical reality of a crash rather than electrical or mechanical noise.10

## **Managing the "Store and Forward" Telemetry Lifecycle**

In the intermittent connectivity environment of Venezuela, data persistence on the mobile device is not an optional feature but a structural requirement.1 The Data Architect must design a system that guarantees 0% data loss in "dead zones" where cellular coverage is absent or unstable.1 This is achieved through the "Store and Forward" lifecycle, where the RTU buffers critical data locally before flushing it to the back-end infrastructure upon reconnection.1

### **Designing the anomaly\_queue in SQLite**

The local persistence layer is implemented using an anomaly\_queue table within a SQLite database on the Flutter mobile application.1 SQLite is selected for its maturity, ACID (Atomicity, Consistency, Isolation, Durability) compliance, and single-file storage architecture, which makes it ideal for handling relational data on resource-constrained mobile devices.12 The anomaly\_queue is designed to be a high-performance staging area for telemetry events that exceed pre-defined behavioral thresholds (e.g., 9G impacts, hard braking, or extreme lean angles).1

The schema for the anomaly\_queue must prioritize temporal integrity. The Data Architect mandates the use of ISO 8601 formatted timestamps (e.g., 2026-03-15T19:44:00.000Z) for every entry.1 While SQLite does not have a dedicated date storage class, storing ISO 8601 values as TEXT ensures they are inherently sortable and easily processed by both the mobile client and the InfluxDB backend.15 This preserves the exact temporal context of an accident, allowing for sub-millisecond sequencing of events that may be flushed minutes or hours after the occurrence.1

| Field Name | Type | Constraints | Description |
| :---- | :---- | :---- | :---- |
| event\_id | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique identifier for local tracking. |
| event\_type | TEXT | NOT NULL | Type of event (e.g., 'IMPACT', 'BRAKE'). |
| timestamp | TEXT | NOT NULL | ISO 8601 UTC timestamp. |
| magnitude | REAL | NOT NULL | Calculated magnitude of acceleration. |
| raw\_data\_blob | BLOB | NULL | Encoded high-res sensor window (3 seconds). |
| sync\_attempts | INTEGER | DEFAULT 0 | Counter for retry logic tracking. |
| bcv\_rate | REAL | NULL | Cached exchange rate at time of event. |

16

To optimize the performance of the anomaly\_queue, the architecture must enable Write-Ahead Logging (WAL) via PRAGMA journal\_mode \= WAL;.14 This improves concurrency, allowing the background telemetry service to write high-frequency records to the queue without blocking the UI thread or inhibiting the reading of data by the synchronization orchestrator.14 Periodic maintenance, such as the VACUUM command, is also mandated to defragment the database file and reduce storage bloat over time.14

### **The Synchronization Orchestrator and Bulk-Sync API**

The transition from "Store" to "Forward" is managed by a synchronization orchestrator that monitors the device's connectivity state using the connectivity\_plus package.1 When the device enters a high-bandwidth area, the orchestrator initiates a bulk transfer to the /api/v1/telemetry/bulk-sync endpoint.1 This endpoint is designed as a RESTful interface adhering to the ACORD Next-Generation Digital Standards for insurance data exchange.1

Given the potential for network failure during a transmission, the synchronization process must be idempotent.1 The Data Architect mandates the use of UUID v4 idempotency keys generated by the mobile client for every sync batch.22 This ensures that if a bulk-sync request is retried due to a timeout, the backend infrastructure—specifically the IBM Power Virtual Server core—does not record duplicate telemetry points, which would skew the risk-scoring algorithms.1 Furthermore, the API utilizes a 207 Multi-Status response model, which allows the server to indicate the success or failure of individual telemetry points within a single batch, enabling the mobile client to prune its local queue selectively and keep only failed records for future retries.24

## **Backend Time-Series Architecture: InfluxDB Integration**

Once telemetry data is successfully "forwarded" to the backend, it is ingested into InfluxDB, a high-performance time-series database.1 The architectural challenge here lies in managing high series cardinality while providing low-latency queries for real-time claim verification.26

### **Schema Optimization: Tags vs. Fields**

The RuedaSeguro backend utilizes InfluxDB 3.0, which supports infinite tag cardinality but still requires a rigorous schema design to optimize query performance and resource usage.27 In this schema, the Data Architect must distinguish between "tags" (metadata used for indexing and grouping) and "fields" (the actual measured values).26

For motorcycle telemetry, the following schema mapping is mandated:

* **Tags (Indexed):** Metadata that remains constant across many data points, such as rider\_id, policy\_id, carrier\_id, and vehicle\_model.26 These are used in WHERE clauses and GROUP BY operations to isolate data for a specific claim or carrier.26  
* **Fields (Non-Indexed):** Highly variable numeric data, including the vector magnitude ![][image3], raw ![][image1] values, and GPS speed.26 Field values are never indexed, as doing so with high-resolution sensor data would lead to runaway cardinality and memory exhaustion.29

| Table / Measurement | Tags | Fields | Data Type |
| :---- | :---- | :---- | :---- |
| impact\_telemetry | rider\_id, carrier\_id | magnitude | Float64 |
| impact\_telemetry | policy\_id | raw\_x, raw\_y, raw\_z | Float64 |
| driving\_behavior | rider\_id, vehicle | max\_g, avg\_speed | Float64 |
| network\_diagnostics | device\_model | sync\_lag\_ms | Int64 |

26

The backend also enforces homogenous table schemas to prevent "sparse schemas" that increase ingestion overhead.28 Every record in the impact\_telemetry table must contain the same set of tag keys to ensure efficient data compaction on disk.28 For archival purposes, RuedaSeguro utilizes shard group durations that are optimized for retention: high-resolution data (nanosecond precision) is kept for 30 days, while downsampled aggregates are retained for up to 5 years to support long-term risk modeling and regulatory audits.31

## **Blockchain Integrity and Logical-to-Physical Mapping**

Trust is a fundamental friction point in the Venezuelan insurance market, where document forgery and claim fraud are rampant.1 RuedaSeguro institutionalizes trust by minting every issued policy as an ERC-721 Non-Fungible Token (NFT) on the Polygon network, following the EIP-1523 standard for insurance policies.1

### **Mitigating Blockchain Bloat**

A critical constraint in blockchain architecture is "bloat"—the accumulation of large amounts of data on the ledger, which increases gas costs and slows down network synchronization.1 Insurance policies are complex documents; a full PDF policy with simplified non-technical language and regulatory disclosures can easily exceed several megabytes.1 Storing this data directly on the Polygon network is technically infeasible.1

The Data Architect solves this through a "Logical-to-Physical" mapping strategy:

* **Physical Tier (Off-Chain):** The actual PDF assets reside in AWS S3.1 S3 is selected for its 11-nines of durability and its ability to handle millions of objects with low latency.35 Access to these documents is controlled via Amazon API Gateway and Lambda authorizers that verify the Ethereum signature of the policyholder or an authorized clinic.35  
* **Logical Tier (On-Chain):** Only a cryptographic SHA-256 hash of the policy document is recorded on the Polygon ledger as part of the NFT’s metadata.1 This hash acts as an immutable "digital fingerprint".37 If even a single character in the PDF is altered, the hash will no longer match the on-chain record, providing an absolute defense against document forgery.1

### **Implementation of EIP-1523 Metadata**

The EIP-1523 standard provides a universal schema for representing insurance policies, enabling interoperability between different insurers and regulatory systems.34 By adopting this standard, RuedaSeguro ensures that its on-chain policy records can be processed by automated adjusters and assistance oracles without human inspection.34

| EIP-1523 Field | Value Type | Purpose |
| :---- | :---- | :---- |
| Policy Holder | Address | Ethereum address of the insured party. |
| Carrier | Address | Identity of the insurance company. |
| Premium | uint256 | Policy payment amount (VES/USD). |
| Coverage Amount | uint256 | Extent of financial protection. |
| Coverage Period | uint64 | Start and end timestamps/blocks. |
| Risk Type | string | e.g., 'Motorcycle\_Parametric\_9G'. |
| Status | uint8 | Active, Expired, or Claimed. |
| Document Hash | bytes32 | SHA-256 hash of the S3 asset. |

34

The synchronization of this metadata is a two-step process. First, the policy PDF is generated and uploaded to S3 with the x-amz-checksum-sha256 header, allowing AWS to perform server-side integrity verification.39 Once S3 confirms the integrity of the upload, the hash is retrieved via the GetObjectAttributes API and passed to the smart contract’s issuePolicy() function.34 This workflow ensures that the on-chain record is only created once the physical asset is safely and accurately stored in the cloud.39

## **Hybrid Infrastructure and Random Access Performance**

The computational demands of the RuedaSeguro ecosystem—ranging from high-velocity telemetry ingestion to AI-driven liability determination—require a hybrid cloud architecture that leverages the specific strengths of IBM Power Systems and AWS.1

### **IBM Power9 as the Transactional Core**

The core transaction engine, which manages the mission-critical Pago Móvil C2P (Cobro a Personas) gateway and the high-volume transactional ledger, is deployed on IBM Power Virtual Server (PowerVS).1 The Power9 architecture is specifically designed as a "performance beast" for the types of random access patterns inherent in a microinsurance ledger where thousands of small, independent policy updates occur every minute.1

Architectural advantages of Power9 for RuedaSeguro include:

* **Radix Tree Address Translation:** This hardware-level feature optimizes the lookup of complex, non-sequential on-chain metadata within system memory, providing up to 3.7 times faster performance than equivalent x86-based environments.1  
* **JSON/BSON Native Storage:** IBM DB2 on Power9 provides optimized performance for the JSON document types used in ACORD-compliant API communication.45 Features like "Fire and Forget" insert modes allow the platform to handle massive bursts of transaction data during end-of-month policy renewal cycles without degrading latency for emergency crash alerts.45  
* **Availability and Resilience:** Utilizing IBM Power Enterprise Pools 2.0, the infrastructure achieves a Recovery Time Objective (RTO) of under 15 minutes, ensuring that an infrastructure outage never prevents a life-saving stabilization payment.1

### **Scalability and Elastic AI via AWS**

While the financial core is secured on IBM Power, RuedaSeguro utilizes AWS for its elastic "Scale-Out" layer.1 This tier handles the front-end components that require near-instant scalability to meet user demand.

* **Frictionless Onboarding:** AWS Textract and Lambda are employed as an OCR engine to extract data from National IDs and vehicle registration (carnet de circulación).1 This automation allows the "Carlos" and "Luis" archetypes to onboard in under 60 seconds, converting the insurance purchase into an "impulse buy".1  
* **Asset Storage:** AWS S3 serves as the durable repository for PDF policies and terms, as previously detailed in the logical-to-physical mapping.1  
* **Hybrid Connectivity:** Secure, low-latency communication between the AWS VPC and the IBM PowerVS workspaces is established using IBM Transit Gateway, ensuring that telemetry data and financial records flow seamlessly between the edge and the core.1

## **Financial Orchestration and Exchange Rate Integration**

In a hyper-inflationary economy, the accuracy of exchange rates is a critical risk factor for both the insurer and the insured.1 The Data Architect must ensure that every financial record is tied to a stable reference point, mitigate inflationary risk through dynamic pricing, and navigate the technical requirements of the Venezuelan payment system.1

### **Integrating the BCV Oracle**

The architectural standard mandates the integration of the Central Bank of Venezuela (BCV) API into every transaction schema.1 Every record—from policy issuance to claim settlement—must include the USD equivalent and the official exchange rate used at the exact second of the transaction.1 This data is retrieved via scraping or dedicated REST interfaces that provide real-time official rates for VES/USD and VES/EUR.43

| Transaction Field | Purpose | Source |
| :---- | :---- | :---- |
| amount\_ves | Local currency settlement value. | Pago Móvil API |
| amount\_usd | Stable reference for coverage limits. | Product Definition |
| exchange\_rate | BCV rate at the second of issuance. | BCV API Oracle |
| rate\_timestamp | Validation of rate freshness. | BCV API Response |

1

This integration prevents "liquidity traps" where the time required to process a claim might result in a payout that has significantly depreciated in purchasing power.1 By index-linking the stabilization payment to the BCV USD rate, RuedaSeguro ensures that the $2,000 trauma payment retains its value for the clinic or the rider.1

### **Pago Móvil C2P Implementation**

To solve the liquidity problem in a landscape where traditional credit card penetration is low, RuedaSeguro integrates the Pago Móvil C2P (Cobro a Personas) gateway.1 This API-driven gateway allows the platform to "pull" premium payments directly from a rider’s bank account using a verified mobile ID.1

The technical requirements for C2P are rigorous:

* **Encryption Standard:** All payment traffic must adhere to the AES/ECB/PKCS5Padding encryption model.1  
* **Authorization Tokens:** The orchestrator must manage temporary 4-digit bank authorization codes and unique ClientIDs passed via the X-IBM-Client-Id HTTP header.1  
* **Idempotency:** Given the intermittent network, the C2P orchestrator must be strictly idempotent to prevent duplicate bank charges during signal drops, ensuring that a single policy is never billed twice.1

## **Security, Privacy, and Regulatory Framework**

As a Data Architect operating under the mandate of the 2024 SUDEASEG regulations (Gaceta Oficial 6.835) and international IoT standards, maintaining the security and privacy of rider data is a primary directive.1

### **Adherence to EN 18031 and Privacy-by-Design**

Because the smartphone RTU relies on radio-connected sensors, compliance with the EN 18031 series of cybersecurity standards is mandatory.1

* **EN 18031-1 (Network Protection):** The RuedaSeguro application is architected to avoid misuse of wireless network resources, implementing exponential back-off and "polite" synchronization schedules to minimize interference during peak cellular congestion.1  
* **EN 18031-2 (Privacy Protection):** The platform implements "privacy-by-design" by limiting geolocation tracking to the minimum required for claim verification.1 High-frequency GPS updates are only activated when the accelerometer detects a potential anomaly, preventing the unnecessary collection of daily movement history.1  
* **EN 18031-3 (Fraud Prevention):** Secure update mechanisms and AES-256 encryption at rest (utilizing SQLCipher for the SQLite database) are mandated to protect personal data and telemetry drivers from malicious injection.1

### **Governance and Social Development Reporting**

Venezuelan law requires insurance carriers to contribute to social development.1 The RuedaSeguro architecture supports this mandate by providing an automated reporting engine for insurers.1 By analyzing anonymized telemetry and demographic data, the platform generates reports that demonstrate the insurer’s contribution to financial inclusion, helping urban workers move from informal, unprotected status to formal, regulated insurance products.1

Furthermore, every blockchain transaction generates an immutable audit trail that allows the regulator (SUDEASEG) to verify that insurance companies are meeting their social protection targets without requiring access to the carrier's proprietary, sensitive databases.1 This "Compliance On-Chain" approach ensures that exclusions—such as unlicensed riders or vehicles outside of covered zones—are automatically verified by smart contracts before a payout is executed, maintaining "Diligence Civil" (Art. 1.270 C.C.).1

## **Future Scaling: AI and Autonomous Settlement**

By Phase 3 (Years 4-5) of the roadmap, the RuedaSeguro ecosystem aims to transition from simple document recognition to "logical reasoning" and autonomous settlement.1

### **Large Language Models for Liability Determination**

The next generation of the data architecture will incorporate Large Language Models (LLMs) to analyze narrative accident statements and witness testimonies.1 These models, deployed on the AI-optimized IBM Power infrastructure, will correlate natural language accounts with objective 9G impact telemetry and reports from "Assistance Oracles" like Venemergencias.1 By fusing objective sensor data with subjective narratives, the system will be able to determine liability autonomously, bypassing the need for human adjusters and reducing administrative costs to near-zero.1

### **Hybrid Parametric-Indemnity Models**

The ultimate goal of the RuedaSeguro ecosystem is a two-layered payout model:

1. **Parametric Layer:** A verified 9G impact trigger initiates an immediate $2,000 stabilization payment to cover medical emergencies in the "golden hour".1  
2. **Indemnity Layer:** AI-driven damage matching analyzes mobile photos of the motorcycle to process a secondary layer for vehicle repairs.1

This hybrid approach ensures that human life is prioritized through immediate liquidity, while the capital asset—the motorcycle—is restored through traditional indemnity processes, all managed within a single, integrated digital pipeline.1

## **Conclusion**

The data architecture designed for RuedaSeguro represents a structural necessity for the evolution of inclusive Insurtech in high-frequency motorcycle markets.1 By transforming the smartphone into a Remote Terminal Unit, implementing the 9G vector magnitude impact trigger, and managing the telemetry lifecycle through a resilient "Store and Forward" SQLite-to-InfluxDB pipeline, the platform overcomes the limitations of intermittent infrastructure and economic volatility.1 The logical-to-physical mapping of blockchain metadata ensures document integrity without ledger bloat, while the integration of official BCV rates and IBM Power9 performance establishes a new global standard for real-time stabilization.1 RuedaSeguro is not merely an insurance application; it is a trustless, autonomous ecosystem that leverages 2026's most advanced data paradigms to solve the most painful human problems of urban logistics.1

#### **Obras citadas**

1. InsurTech Enterprise Architecture Roadmap  
2. LSM9DS1 “9 Axis” Accelerometer, fecha de acceso: marzo 15, 2026, [https://courses.physics.illinois.edu/phys371/sp2023/documents/week7.pdf](https://courses.physics.illinois.edu/phys371/sp2023/documents/week7.pdf)  
3. On-Board Smartphone-Based Road Hazard Detection with Cloud-Based Fusion \- MDPI, fecha de acceso: marzo 15, 2026, [https://www.mdpi.com/2624-8921/5/2/31](https://www.mdpi.com/2624-8921/5/2/31)  
4. Current Models for Implementing Crash Detection in Digital Mobile Platforms, fecha de acceso: marzo 15, 2026, [https://ulopenaccess.com/papers/ULETE\_V02I03/ULETE20250203\_003.pdf](https://ulopenaccess.com/papers/ULETE_V02I03/ULETE20250203_003.pdf)  
5. Accelerometers in Our Pocket: Does Smartphone Accelerometer Technology Provide Accurate Data? \- PMC, fecha de acceso: marzo 15, 2026, [https://pmc.ncbi.nlm.nih.gov/articles/PMC9824767/](https://pmc.ncbi.nlm.nih.gov/articles/PMC9824767/)  
6. Validity of smartphone sensors to assess selected kinetic and kinematic outcomes during single-leg landing stabilization tasks | PLOS One \- Research journals, fecha de acceso: marzo 15, 2026, [https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0319744](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0319744)  
7. A Feature Engineering Method for Smartphone-Based Fall Detection \- MDPI, fecha de acceso: marzo 15, 2026, [https://www.mdpi.com/1424-8220/25/20/6500](https://www.mdpi.com/1424-8220/25/20/6500)  
8. Designing Butterworth high pass filter for accelerometer \- MATLAB Answers \- MathWorks, fecha de acceso: marzo 15, 2026, [https://www.mathworks.com/matlabcentral/answers/267858-designing-butterworth-high-pass-filter-for-accelerometer](https://www.mathworks.com/matlabcentral/answers/267858-designing-butterworth-high-pass-filter-for-accelerometer)  
9. Digital Butterworth filter for subtracting noise from low magnitude surface electromyogram \- PubMed, fecha de acceso: marzo 15, 2026, [https://pubmed.ncbi.nlm.nih.gov/17548125/](https://pubmed.ncbi.nlm.nih.gov/17548125/)  
10. Digital Filtering High-pass & Low-pass Filters \- enDAQ, fecha de acceso: marzo 15, 2026, [https://endaq.com/pages/digital-filtering](https://endaq.com/pages/digital-filtering)  
11. Design of Digital Low-Pass Filters for Time-Domain Recursive Filtering of Impact Acceleration Signals. \- DTIC, fecha de acceso: marzo 15, 2026, [https://apps.dtic.mil/sti/tr/pdf/ADA293086.pdf](https://apps.dtic.mil/sti/tr/pdf/ADA293086.pdf)  
12. Mastering SQLite for Local Flutter Storage \- Medium, fecha de acceso: marzo 15, 2026, [https://medium.com/@nakiboddin.saiyad/mastering-sqlite-for-local-flutter-storage-4b932efce985](https://medium.com/@nakiboddin.saiyad/mastering-sqlite-for-local-flutter-storage-4b932efce985)  
13. Offline-First Architecture in Flutter: Part 1 — SQLite Local Storage and Conflict Resolution, fecha de acceso: marzo 15, 2026, [https://dev.to/anurag\_dev/implementing-offline-first-architecture-in-flutter-part-1-local-storage-with-conflict-resolution-4mdl](https://dev.to/anurag_dev/implementing-offline-first-architecture-in-flutter-part-1-local-storage-with-conflict-resolution-4mdl)  
14. Best Practices for Managing Schema, Indexes, and Storage in SQLite for Data Engineering | by firman brilian | Medium, fecha de acceso: marzo 15, 2026, [https://medium.com/@firmanbrilian/best-practices-for-managing-schema-indexes-and-storage-in-sqlite-for-data-engineering-266b7fa65f4c](https://medium.com/@firmanbrilian/best-practices-for-managing-schema-indexes-and-storage-in-sqlite-for-data-engineering-266b7fa65f4c)  
15. Handling Timestamps in SQLite, fecha de acceso: marzo 15, 2026, [https://blog.sqlite.ai/handling-timestamps-in-sqlite](https://blog.sqlite.ai/handling-timestamps-in-sqlite)  
16. How to stores dates for my use case (best query performance). \- SQLite User Forum, fecha de acceso: marzo 15, 2026, [https://www.sqlite.org/forum/info/5203f28a039a028754fda31591bbfb3c9ca9a949277cb45d789a2f78aecbd52f?t=h](https://www.sqlite.org/forum/info/5203f28a039a028754fda31591bbfb3c9ca9a949277cb45d789a2f78aecbd52f?t=h)  
17. SQLite Date & Time \- How To Handle Date and Time in SQLite \- SQLite Tutorial, fecha de acceso: marzo 15, 2026, [https://www.sqlitetutorial.net/sqlite-date/](https://www.sqlitetutorial.net/sqlite-date/)  
18. SQLite in Flutter: The Complete Guide \- DEV Community, fecha de acceso: marzo 15, 2026, [https://dev.to/arslanyousaf12/sqlite-in-flutter-the-complete-guide-11nj](https://dev.to/arslanyousaf12/sqlite-in-flutter-the-complete-guide-11nj)  
19. How to persist data in Flutter using SQLite \- LogRocket Blog, fecha de acceso: marzo 15, 2026, [https://blog.logrocket.com/flutter-sqlite-how-to-persist-data/](https://blog.logrocket.com/flutter-sqlite-how-to-persist-data/)  
20. SQLite ETL Tools: Lightweight Pipelines for Edge & Mobile Apps | Integrate.io, fecha de acceso: marzo 15, 2026, [https://www.integrate.io/blog/sqlite-etl-tools-lightweight-pipelines/](https://www.integrate.io/blog/sqlite-etl-tools-lightweight-pipelines/)  
21. High performance sqlite for Flutter (optimized sqlite3) : r/FlutterDev \- Reddit, fecha de acceso: marzo 15, 2026, [https://www.reddit.com/r/FlutterDev/comments/12bhpxh/high\_performance\_sqlite\_for\_flutter\_optimized/](https://www.reddit.com/r/FlutterDev/comments/12bhpxh/high_performance_sqlite_for_flutter_optimized/)  
22. Implementing Idempotency Keys in REST APIs \- Zuplo, fecha de acceso: marzo 15, 2026, [https://zuplo.com/learning-center/implementing-idempotency-keys-in-rest-apis-a-complete-guide](https://zuplo.com/learning-center/implementing-idempotency-keys-in-rest-apis-a-complete-guide)  
23. Rest API Design: Implementing Idempotency | by Vahid Najafi \- Medium, fecha de acceso: marzo 15, 2026, [https://medium.com/@vahid.vdn/rest-api-idempotency-design-3c69500811c2](https://medium.com/@vahid.vdn/rest-api-idempotency-design-3c69500811c2)  
24. How to Implement Bulk Operations in REST APIs \- OneUptime, fecha de acceso: marzo 15, 2026, [https://oneuptime.com/blog/post/2026-01-27-rest-api-bulk-operations/view](https://oneuptime.com/blog/post/2026-01-27-rest-api-bulk-operations/view)  
25. RESTful API Design Guide: Principles & Best Practices \- Strapi, fecha de acceso: marzo 15, 2026, [https://strapi.io/blog/restful-api-design-guide-principles-best-practices](https://strapi.io/blog/restful-api-design-guide-principles-best-practices)  
26. InfluxDB schema design \- InfluxData Documentation, fecha de acceso: marzo 15, 2026, [https://docs.influxdata.com/influxdb/v2/write-data/best-practices/schema-design/](https://docs.influxdata.com/influxdb/v2/write-data/best-practices/schema-design/)  
27. InfluxDB schema design recommendations and best practices \- InfluxData Documentation, fecha de acceso: marzo 15, 2026, [https://docs.influxdata.com/influxdb3/cloud-dedicated/write-data/best-practices/schema-design/](https://docs.influxdata.com/influxdb3/cloud-dedicated/write-data/best-practices/schema-design/)  
28. InfluxDB schema design recommendations and best practices \- InfluxData Documentation, fecha de acceso: marzo 15, 2026, [https://docs.influxdata.com/influxdb3/enterprise/write-data/best-practices/schema-design/](https://docs.influxdata.com/influxdb3/enterprise/write-data/best-practices/schema-design/)  
29. Understanding how to choose between fields and tags in InfluxDB, fecha de acceso: marzo 15, 2026, [https://dba.stackexchange.com/questions/163292/understanding-how-to-choose-between-fields-and-tags-in-influxdb](https://dba.stackexchange.com/questions/163292/understanding-how-to-choose-between-fields-and-tags-in-influxdb)  
30. Writing my first schema. Tags confuse me \- InfluxDB 2 \- InfluxData Community Forums, fecha de acceso: marzo 15, 2026, [https://community.influxdata.com/t/writing-my-first-schema-tags-confuse-me/32094](https://community.influxdata.com/t/writing-my-first-schema-tags-confuse-me/32094)  
31. Designing Your Schema \- Time to Awesome \- InfluxData, fecha de acceso: marzo 15, 2026, [https://awesome.influxdata.com/docs/part-2/designing-your-schema/](https://awesome.influxdata.com/docs/part-2/designing-your-schema/)  
32. InfluxDB schema design and data layout \- InfluxData Documentation, fecha de acceso: marzo 15, 2026, [https://docs.influxdata.com/influxdb/v1/concepts/schema\_and\_data\_layout/](https://docs.influxdata.com/influxdb/v1/concepts/schema_and_data_layout/)  
33. InfluxDB schema design recommendations and best practices \- InfluxData Documentation, fecha de acceso: marzo 15, 2026, [https://docs.influxdata.com/influxdb3/cloud-serverless/write-data/best-practices/schema-design/](https://docs.influxdata.com/influxdb3/cloud-serverless/write-data/best-practices/schema-design/)  
34. EIP-1523: Insurance policy Standard using ERC-721 Token Standard Non-fungible Token (NFT). | by Honour Marcus | Medium, fecha de acceso: marzo 15, 2026, [https://medium.com/@honourmarcus9/eip-1523-insurance-policy-standard-using-erc-721-token-standard-non-fungible-token-nft-ab628e4ad3bf](https://medium.com/@honourmarcus9/eip-1523-insurance-policy-standard-using-erc-721-token-standard-non-fungible-token-nft-ab628e4ad3bf)  
35. Build NFT metadata access control with Ethereum signatures and AWS Lambda authorizers, fecha de acceso: marzo 15, 2026, [https://aws.amazon.com/blogs/database/build-nft-metadata-access-control-with-ethereum-signatures-and-aws-lambda-authorizers/](https://aws.amazon.com/blogs/database/build-nft-metadata-access-control-with-ethereum-signatures-and-aws-lambda-authorizers/)  
36. Accelerate Data Modernization and AI with IBM Databases on AWS | IBM & Red Hat on AWS, fecha de acceso: marzo 15, 2026, [https://aws.amazon.com/blogs/ibm-redhat/accelerate-data-modernization-and-ai-with-ibm-databases-on-aws/](https://aws.amazon.com/blogs/ibm-redhat/accelerate-data-modernization-and-ai-with-ibm-databases-on-aws/)  
37. Structure Your Token Metadata Using JSON Schema V2 \- Hedera Docs, fecha de acceso: marzo 15, 2026, [https://docs.hedera.com/hedera/tutorials/token/structure-your-token-metadata-using-json-schema-v2](https://docs.hedera.com/hedera/tutorials/token/structure-your-token-metadata-using-json-schema-v2)  
38. fecha de acceso: marzo 15, 2026, [https://raw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-2477.md](https://raw.githubusercontent.com/ethereum/ERCs/master/ERCS/erc-2477.md)  
39. Checking object integrity for data uploads in Amazon S3 \- AWS Documentation, fecha de acceso: marzo 15, 2026, [https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity-upload.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity-upload.html)  
40. How do I calculate an AWS S3 compatible SHA-256 hash from a Blob in Angular?, fecha de acceso: marzo 15, 2026, [https://repost.aws/questions/QU5irBWwpdQnKDUsBFRKAq\_w/how-do-i-calculate-an-aws-s3-compatible-sha-256-hash-from-a-blob-in-angular](https://repost.aws/questions/QU5irBWwpdQnKDUsBFRKAq_w/how-do-i-calculate-an-aws-s3-compatible-sha-256-hash-from-a-blob-in-angular)  
41. S3: Generating PUT Presigned URLs with SHA1/SHA256 Checksum validation results in a URL that is rejected due to UnsignedHeaders · Issue \#3906 · aws/aws-sdk-js-v3 \- GitHub, fecha de acceso: marzo 15, 2026, [https://github.com/aws/aws-sdk-js-v3/issues/3906](https://github.com/aws/aws-sdk-js-v3/issues/3906)  
42. amazon web services \- AWS S3 \- Etag Sha256 instead of Md5 \- Stack Overflow, fecha de acceso: marzo 15, 2026, [https://stackoverflow.com/questions/44107504/aws-s3-etag-sha256-instead-of-md5](https://stackoverflow.com/questions/44107504/aws-s3-etag-sha256-instead-of-md5)  
43. jrafaaael/cbv \- GitHub, fecha de acceso: marzo 15, 2026, [https://github.com/jrafaaael/cbv](https://github.com/jrafaaael/cbv)  
44. bcv · GitHub Topics, fecha de acceso: marzo 15, 2026, [https://github.com/topics/bcv](https://github.com/topics/bcv)  
45. Db2 12 \- JSON \- Performance features \- IBM, fecha de acceso: marzo 15, 2026, [https://www.ibm.com/docs/en/db2-for-zos/12.0.0?topic=planning-performance-features](https://www.ibm.com/docs/en/db2-for-zos/12.0.0?topic=planning-performance-features)  
46. Db2 12.1 – in the World of AI \- Hosted By One.com | Webhosting made simple, fecha de acceso: marzo 15, 2026, [https://usercontent.one/wp/www.middlecon.se/wp-content/uploads/2025/09/Nordics-Db2-12.1-In-the-World-of-AI-1.pdf?media=1750323972](https://usercontent.one/wp/www.middlecon.se/wp-content/uploads/2025/09/Nordics-Db2-12.1-In-the-World-of-AI-1.pdf?media=1750323972)  
47. IBM DB2 Warehouse, fecha de acceso: marzo 15, 2026, [https://www.ibm.com/products/db2-warehouse](https://www.ibm.com/products/db2-warehouse)  
48. Update Rate BCV \- Enterprise Edition \- Odoo Apps Store, fecha de acceso: marzo 15, 2026, [https://apps.odoo.com/apps/modules/17.0/xeleste\_rate\_live\_bcv](https://apps.odoo.com/apps/modules/17.0/xeleste_rate_live_bcv)  
49. Venezuelan Bolivares to U.S. Dollar Spot Exchange Rate (AEXVZUS) | FRED | St. Louis Fed, fecha de acceso: marzo 15, 2026, [https://fred.stlouisfed.org/series/AEXVZUS](https://fred.stlouisfed.org/series/AEXVZUS)  
50. rafnixg/bcv-api: BCV Exchange rate: This API is used to get the exchange rate of the BCV (Central Bank of Venezuela) \- GitHub, fecha de acceso: marzo 15, 2026, [https://github.com/rafnixg/bcv-api](https://github.com/rafnixg/bcv-api)  
51. Venezuela \- Key Message Update: Temporary price spikes dissipate, while seasonal trends bolster food access (January 2026\) \- ReliefWeb, fecha de acceso: marzo 15, 2026, [https://reliefweb.int/report/venezuela-bolivarian-republic/venezuela-key-message-update-temporary-price-spikes-dissipate-while-seasonal-trends-bolster-food-access-january-2026](https://reliefweb.int/report/venezuela-bolivarian-republic/venezuela-key-message-update-temporary-price-spikes-dissipate-while-seasonal-trends-bolster-food-access-january-2026)  
52. Fleet Management Software Integrations Guide for Modern Logistics \- Relinns, fecha de acceso: marzo 15, 2026, [https://relinns.com/blogs/fleet-software-integrations](https://relinns.com/blogs/fleet-software-integrations)  
53. What is AI Storage? \- IBM, fecha de acceso: marzo 15, 2026, [https://www.ibm.com/think/topics/ai-storage](https://www.ibm.com/think/topics/ai-storage)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEkAAAAZCAYAAAB9/QMrAAACn0lEQVR4Xu2WTahNURiGX6EI+Q9RLhmQgYES5SdlSjJBSncgP5lRlHIpiYFS/qaSMDAwkJIMrkjKwISJDA4TGVIGKLzvXWud863vnFvn7HP24NZ66m3v9a191ru/dda31gYKhUKhUCgUCt0yiZrngzWRvKb6jhqQV98+M6jL1DdqlDpGnacOIhgMGuv1BfV52bzkY/PqiZnUL2qLid2k/lFHTGwQyOsZci9Rh5d8BpbXUeoJNc3EnlM/qfUmNgjkpZe0Xvq36/CSj81LPpXymk29QfvMfqXeUnNdvB+Sl17eshL1ePkVI59Kea2jfsSrRQa3Mdg9InlJll2oz8vmJZ9KeWnZafktcHENdoCaQu13fVVJXh9c/CJyr4V5dyXkJR+bl3xsXl37TKceU0tjW0fyQ+oztQRhDxmhdlJ74zO634hQ35JqXaSa14tsijFL8mrEdvL6i9xLpXIF4eQ7EZ9VqWyO9wn5SPtcXMirgTwv+di8EscRcrtAvaOWm74my6j31B3qE8IP/lAvqJcIP9pDzYnPq86ViJayH1B9vxEmshPyeo3caxi51xC1HeHIThusSiUlnPiOkPhpF0/Ix+Y1jDwvzzlqlQ9a5lOL0Prg0lFt2wnV8j0X68R4kyQ0hh/bt8VThBUhriE/ERMqnfEmST7d5qWVpj+wLzS4VpJqPO0pKq8VzSdaKLE1PtgjGvtMvJf3aKuriSbhKrXDd/TIYoQPTiHftaavJ+5Tl6gb1F3qLHUI7aeEyuWVi1VFR/UphH2ikXeNoW8glWFVtHlrM99K7UbY306iPaeumYywdHUVnZa+0Eob8sEKaHytII13i3qQd4+xGn0khJDLLNOW34RBE/QI4aU3UB/jtWBQGVynDiN8UmzLuwuFich/0WqBjDzxMyYAAAAASUVORK5CYII=>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAFMAAAAZCAYAAABNcRIKAAADuklEQVR4Xu2XS6hNYRTHlxDyfuQREzIhomRAYsCARPJMBopEmAkzJRmYySOP6GZgII8oZGBwSyFKFCmjSx4DSYQSYf3u2quzznf2Ofecc2/do/a//p2z1/4e61uvb22RAgUKFCjQLFYpzyvPJjwTB/UCRiiPSaVeF+KgVsNM5VrlReVn5a7seXEc1CT6K8ekwjoxWLlcuU35V3lFTC/Y0hiqvKfclL7oBvoo25RL0hcNYrXysXJk+qJVMU35STknfdENcHiMMDF90SBIdZyCc/4L4H1SqRHvk8KjUmHALOVXZb/0RQNoNmMmKAemQsUQsVrs4AzjwnMtxHk1gfcxZj0YLxYpH5VPlBvFLjCiGzwTWyvytdgBG4VnDI7pCkTuQuUjZbvyh9i5qL2826N8pfymHKY8onynfKs8IWbYFMxbo3wpNveccr/yQBwU4QoTRV1htPK9cmqQYagOKU9nT3Hk3UG9Tt6n/CNmMAeReUvsbNvFjOCyOA6wx4pEtkFszUNSKjHrxcYe9kEpPMU5fIq+YobxxVCIA0bgBBSMaUXt/S52AzcLT/FqxiRlfU+6EKInpqwbjvmbxYIGh3dIZTnDaOlFyXqsOyPI3LnLgqwMPoAQTjFPTE7do8V5IZWbMhcjR1Dj8uSNoFbGoA96oR9gL1I1XlKu768gW5A8AwzbIZUXJWu2izkN8MvzB+WUTFYGT0cm5hX548qV2X+Ptkml153I8yoHRWmUbxbukLyMIVquih0Q5unv+nYEGc5NIx0d26SyW0jT2Z3bLiUDl8EHsGleW/RASqnjysWFoldZa10m83qJnPEcdEDnjPrhGcNBU+Cs3dl/1s/T3w13NHv2tE8jnX2WikU7NdEvSuZSAh1eDqvWS7zLAL5+8Aw3GgbYqvwi5RE3SHlHSvUG43HD8Xk3XHlZOVlKLZF/9lH3YjSzX60SQJ3mcD/FbuS5mZzWhLVvSGWNJgt2hGfO9UY5O8g8xWM582Biz4NSvgbdil8+3P7onJvi1BqU9YNVY1qo2RzjcCBaEA7HBveVe6XkkFNibcc1Kb/5wXPlb8mPOA6V6pDHNKV3ihn+pvKSWLRhgIgtYnO9bAF05Xv/tlirFNujRWKXEHbyy+iuWKvVYxibkYMD2qW0ocWoyBmXB6KEetyT8AY83ugR/pGR1kaeU/3zgCOqpnhvgnpH79eqIPooaxF5F22v47RUNs2tBOr/Q7FeksuIi4f6m3YxLYHpkv/p1krAiNeVT5UnlfPLXxcoUKBAgWbwD0Gl4QHRx3amAAAAAElFTkSuQmCC>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAaCAYAAACO5M0mAAAAlElEQVR4XmNgGHogHojnAvEsJAziRyErAgFzIA4B4qVA/B+In0H58siKkMEcBojC+egSyEAQiE8zQBRGo8mhAJAkSBFIMUgTTjCJAaIQZD1OQLS1mkD8Fog/AbE+mhwKINp9RFkLAiArvwKxMboEOgCZdhWIRdAlkAE/A0ThWiBmR5MDA08GiAJ0fACIeRDKRgE1AABrtiS5oX9iEgAAAABJRU5ErkJggg==>

[image4]: <data:image/png;base64,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>

[image5]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAaCAYAAACO5M0mAAAAu0lEQVR4XmNgGAW0AqxALATEjOgSyGA+EL8G4nNAfAGII4FYE0UFVGAOEHNC+cFA/BeIbeAqgEAYiE8BsQqSmCQQPwRiaSQxhnIg/o8sAAT6QPwJiDlgAsZA/BWIn8AEoGASEP9DFoApPIAkJgjEp4H4AQPE7aEgQZgVC+HKGBhsgfgnEG9lgDgrHSQI8uUOBogJIAAy4RYDxM0gzauBWBEqB5a8BsQbGSC+B9kyC4ifA3EpA4HAHwXEAwBwySC2kyq3DgAAAABJRU5ErkJggg==>