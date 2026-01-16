# MLOps Tutorial: A Technical Walkthrough

This guide accompanies the `mlops_tutorial.ipynb` notebook, providing context, technical insights, and interesting facts about each section.

---

## Overview

The tutorial demonstrates a complete MLOps workflow using a custom abstraction layer built on top of MLflow. It covers the full lifecycle from experiment tracking to model deployment—a journey that mirrors real-world ML engineering practices at companies like Netflix, Uber, and Airbnb.

---

## Part 1: Experiment Tracking

### Cell 1: Initialization

```python
client = MLflowClient(server_uri="http://localhost:5050")
tracker = MLflowExperimentTracker(client)
registry = MLflowModelRegistry(client)
```

**What's happening:** The code establishes connections to three core components:
- **MLflowClient**: The low-level API wrapper for HTTP communication with the MLflow server
- **MLflowExperimentTracker**: A higher-level abstraction for managing experiments and runs
- **MLflowModelRegistry**: Handles model versioning and stage management

**Technical insight:** The environment variables for MinIO (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) follow the S3 protocol specification. MLflow treats MinIO as an S3-compatible backend, which is why we use AWS-prefixed variables even though we're not using AWS.

**Fun fact:** MLflow was originally developed at Databricks in 2018. The name "MLflow" represents the concept of managing the "flow" of ML artifacts—data, code, and models—through the development lifecycle.

---

### Cell 2: Creating Experiments and Training

```python
experiment = tracker.create_experiment(name=experiment_name)
with experiment.start_run("xgboost_training") as run:
    ...
```

**What's happening:** 
1. Creates a named experiment container (think of it as a folder for related runs)
2. Uses Python's context manager (`with` statement) to automatically handle run lifecycle
3. Trains an XGBoost classifier on synthetic classification data
4. Logs parameters, metrics, the model itself, and the training dataset

**Technical insight:** The `make_classification` function from scikit-learn generates a random n-class classification problem with controllable properties. Using `n_informative=15` out of `n_features=20` means 15 features carry signal while 5 are noise—a realistic scenario.

**Key methods demonstrated:**
- `run.log_params()` — Records hyperparameters as key-value pairs
- `run.log_metrics()` — Records numerical performance metrics
- `run.log_model()` — Serializes and stores the trained model with its flavor (framework type)
- `run.log_data()` — Versions the training dataset with optional quality metrics

**Fun fact:** XGBoost (eXtreme Gradient Boosting) won 17 out of 29 Kaggle competitions in 2015. Its name comes from pushing the limits of gradient boosting computation—the "extreme" refers to both speed and performance optimizations.

---

### Cell 3: Listing Experiments and Runs

```python
experiments = tracker.list_experiments(max_results=10)
runs = experiment.list_runs()
```

**What's happening:** Queries the MLflow backend to retrieve metadata about all experiments and their runs. This is the equivalent of browsing your experiment history.

**Technical insight:** MLflow stores experiment and run metadata in a relational database (SQLite by default, PostgreSQL in production). The artifacts (models, datasets) are stored separately in the artifact store (MinIO/S3 in this case). This separation allows efficient metadata queries without loading large binary files.

**Fun fact:** Google's research shows that ML practitioners typically run 10-100 experiments per project, but only 1-2% make it to production. Good experiment tracking helps identify that winning 1%.

---

### Cell 4: Deleting a Run

```python
experiment.delete_run(temp_run_id)
```

**What's happening:** Demonstrates run-level cleanup. In MLflow, deleted runs are "soft deleted"—marked as deleted but not immediately removed from storage.

**Technical insight:** Soft deletion allows recovery of accidentally deleted runs. The actual cleanup happens during garbage collection, which can be triggered manually or scheduled. This follows the same pattern as Git's reflog.

**Why this matters:** In production environments, teams often generate hundreds of runs during hyperparameter searches. Without cleanup, storage costs and UI clutter become real problems.

---

### Cell 5: Deleting an Experiment

```python
tracker.delete_experiment(temp_experiment.id)
```

**What's happening:** Removes an entire experiment and all its associated runs. Like run deletion, this is typically a soft delete.

**Technical insight:** Experiment deletion cascades to all runs within it. In a team setting, this operation is often restricted to admins to prevent accidental data loss.

---

## Part 2: Model Registry

### Cell 6: Registering a Model

```python
registered_model = registry.register_model(
    name=registered_model_name,
    source_uri=logged_model_uri,
    version="v1_0_0",
    tags={...}
)
```

**What's happening:** Promotes a model from an experiment artifact to a registered, named entity in the model registry. This is the transition from "research artifact" to "production candidate."

**Technical insight:** The `source_uri` points to the model's location in the artifact store (e.g., `s3://mlflow/1/abc123/artifacts/model`). Registration creates a reference—not a copy—so the underlying artifacts are shared.

**Key concepts:**
- **Model name**: A human-readable identifier (e.g., `fraud_detector`, `recommendation_model`)
- **Version**: Auto-incremented integer, with optional semantic aliases
- **Tags**: Arbitrary metadata for filtering and documentation

**Fun fact:** The concept of a "model registry" was popularized by Netflix's Metaflow and later adopted by MLflow, Kubeflow, and AWS SageMaker. It's inspired by software package registries like npm and PyPI.

---

### Cell 7: Listing Model Versions

```python
model_versions = registry.list_model_versions(name=registered_model_name)
latest_model = registry.get_model_version(name=registered_model_name)
```

**What's happening:** Retrieves all versions of a registered model and fetches the latest one. This enables version comparison and rollback scenarios.

**Technical insight:** Model versions are immutable once created. You can add tags and change stages, but you cannot modify the underlying model. This immutability is crucial for reproducibility and audit trails.

**Why this matters:** In production, you might need to quickly roll back to a previous model version if the new one underperforms. The registry makes this a single API call.

---

### Cell 8: Downloading a Model

```python
success = registered_model.download_model(download_path=download_path)
```

**What's happening:** Retrieves model artifacts from the remote storage to a local directory. This is how models get deployed to serving infrastructure.

**Technical insight:** Downloaded artifacts typically include:
- `model.json` / `model.pkl` — The serialized model
- `conda.yaml` / `requirements.txt` — Environment dependencies
- `MLmodel` — Metadata file describing the model flavor and signature
- `python_env.yaml` — Python version and package specifications

**Fun fact:** The "flavor" system in MLflow is clever—it allows the same model to be loaded using different frameworks. An XGBoost model can be loaded via `mlflow.xgboost`, `mlflow.pyfunc`, or even served as a REST API without code changes.

---

### Cell 9: Stage Promotion

```python
registered_model.set_stage("Staging")
registered_model.set_stage("Production")
```

**What's happening:** Moves the model through lifecycle stages: `None` → `Staging` → `Production`. This implements a basic promotion workflow.

**Stage definitions:**
- **None**: Just registered, not validated
- **Staging**: Under testing/validation
- **Production**: Serving live traffic
- **Archived**: Deprecated, kept for reference

**Technical insight:** In enterprise settings, stage transitions often trigger automated actions:
- `→ Staging`: Runs integration tests, A/B test configuration
- `→ Production`: Updates load balancers, triggers canary deployments
- `→ Archived`: Drains existing traffic, marks for cleanup

**Fun fact:** LinkedIn's Pro-ML system handles 1 million model predictions per second. Their promotion workflow includes 47 automated validation steps before a model reaches production.

---

### Cell 10: Loading and Using the Model

```python
model_uri = f"models:/{registered_model_name}/{registered_model.version}"
loaded_model = mlflow.xgboost.load_model(model_uri)
predictions = loaded_model.predict(X_test)
```

**What's happening:** Loads the production model directly from the registry using MLflow's model URI scheme and makes predictions.

**Technical insight:** The `models:/` URI scheme is MLflow's way of abstracting storage details. You can reference models by:
- `models:/model_name/version_number` — Specific version
- `models:/model_name/Staging` — Latest in staging
- `models:/model_name/Production` — Latest in production

**Why this matters:** This abstraction means your serving code doesn't need to know where models are physically stored. Change your artifact store, and the code still works.

---

### Cell 11: Cleanup

```python
registry.delete_model(name=registered_model_name)
tracker.delete_experiment(experiment.id)
```

**What's happening:** Removes all resources created during the tutorial—downloaded files, registered model, and the experiment.

**Technical insight:** In production, cleanup is often handled by retention policies rather than manual deletion. Common approaches:
- Delete experiments older than 90 days
- Archive models not accessed in 6 months
- Remove non-production model versions after 30 days

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Code                                │
│  ┌──────────────┐  ┌──────────────────┐  ┌─────────────────┐   │
│  │ MLflowClient │  │ ExperimentTracker │  │ ModelRegistry   │   │
│  └──────┬───────┘  └────────┬─────────┘  └────────┬────────┘   │
└─────────┼───────────────────┼─────────────────────┼────────────┘
          │                   │                     │
          ▼                   ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MLflow Tracking Server                       │
│                    (http://localhost:5050)                      │
│  ┌─────────────────────┐    ┌────────────────────────────────┐ │
│  │ Metadata Store      │    │ REST API                       │ │
│  │ (PostgreSQL/SQLite) │    │ - /api/2.0/mlflow/experiments  │ │
│  │ - experiments       │    │ - /api/2.0/mlflow/runs         │ │
│  │ - runs              │    │ - /api/2.0/mlflow/models       │ │
│  │ - model versions    │    └────────────────────────────────┘ │
│  └─────────────────────┘                                        │
└─────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MinIO (S3-Compatible)                        │
│                    (http://localhost:9000)                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Artifact Store                                           │   │
│  │ s3://mlflow-artifacts/                                   │   │
│  │ ├── experiment_id/                                       │   │
│  │ │   └── run_id/                                          │   │
│  │ │       └── artifacts/                                   │   │
│  │ │           ├── model/                                   │   │
│  │ │           └── training_data/                           │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Takeaways

1. **Separation of concerns**: Metadata (fast queries) vs. artifacts (large files) are stored separately
2. **Immutability**: Logged artifacts and model versions cannot be modified—only metadata can change
3. **URI abstraction**: Reference models and artifacts by logical names, not physical paths
4. **Lifecycle management**: Stage-based promotion enables controlled rollouts
5. **Reproducibility**: Every run captures parameters, code version, and data lineage

---

## Further Reading

- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [XGBoost Paper](https://arxiv.org/abs/1603.02754) — "XGBoost: A Scalable Tree Boosting System"
- [Hidden Technical Debt in ML Systems](https://papers.nips.cc/paper/5656-hidden-technical-debt-in-machine-learning-systems) — The seminal paper on ML infrastructure challenges
- [Uber's Michelangelo](https://eng.uber.com/michelangelo-machine-learning-platform/) — Real-world MLOps at scale
