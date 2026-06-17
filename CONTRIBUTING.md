# Contributing to StrainFlow

Thank you for your interest in contributing! StrainFlow is an open-source project under
GPL v3.0. Contributions of all kinds are welcome: bug reports, documentation improvements,
new modules, and performance improvements.

---

## Getting started

1. **Fork** the repository on GitHub.
2. **Clone** your fork:
   ```bash
   git clone https://github.com/<your-username>/StrainFlow.git
   cd StrainFlow
   ```
3. **Create a branch** for your change:
   ```bash
   git checkout -b feat/my-new-feature
   ```

---

## Development environment

```bash
# Install Python test dependencies
pip install pandas pyarrow pytest pytest-cov

# Run Python unit tests
pytest tests/ -v

# Install Nextflow (required for pipeline validation)
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# Validate schema
nf-core schema validate . params.yaml
```

---

## Code style

### Nextflow modules

- One process per file in `modules/`
- Each process must have:
  - A `tag` directive using `$meta.id`
  - A `label` directive (`small` | `medium` | `large` | `xlarge`)
  - A `container` directive with a **pinned version** (no `latest`)
  - `publishDir` pointing into `${params.outdir}`
- Document any non-obvious flags in a comment above the process block

### Python scripts

- Target Python 3.10+
- All public functions must have docstrings
- Type hints required for function signatures
- Use `logging` (not `print`) for diagnostic output
- Every new helper script needs corresponding tests in `tests/`

### Configuration

- Any new parameter must be added to:
  1. `nextflow.config` (default value)
  2. `nextflow_schema.json` (type + description)
  3. `params.yaml` (example value with comment)

---

## Adding a new module

1. Create `modules/my_tool.nf` following the existing pattern.
2. Add the container image to `containers/containers.md`.
3. Add the tool to `conda/environment.yml` (pinned version).
4. Add the tool to `TOOL_VERSION_CMDS` in `bin/generate_manifest.py`.
5. Include the module in the appropriate subworkflow or `main.nf`.
6. Update the README DAG diagram and scientific rationale if relevant.

---

## Pull request checklist

- [ ] Tests pass: `pytest tests/ -v`
- [ ] No `latest` Docker tags
- [ ] New parameters documented in schema + params.yaml
- [ ] Commits are atomic and have clear messages
- [ ] PR description explains the motivation and scientific justification

---

## Reporting bugs

Please open a GitHub Issue with:
- Nextflow version (`nextflow -version`)
- Profile used (`local` / `aws` / `test`)
- Error message (paste the `.nextflow.log` if helpful)
- A minimal reproducible samplesheet (even synthetic reads)

---

## Code of conduct

Be respectful and constructive. See the [Contributor Covenant](https://www.contributor-covenant.org/) v2.1.
