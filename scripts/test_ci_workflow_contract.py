import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CI_WORKFLOW = ROOT / ".github" / "workflows" / "ci.yml"


def _job_block(workflow: str, job_name: str) -> str:
    marker = f"  {job_name}:\n"
    start = workflow.index(marker)
    remainder = workflow[start + len(marker) :]
    next_job = re.search(r"(?m)^  [a-z0-9-]+:\n", remainder)
    end = len(workflow) if next_job is None else start + len(marker) + next_job.start()
    return workflow[start:end]


class TestCiWorkflowContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = CI_WORKFLOW.read_text(encoding="utf-8")

    def test_edge_change_detector_ignores_documentation_only_pushes(self):
        detector = _job_block(self.workflow, "edge-function-changes")

        self.assertIn("supabase/functions/", detector)
        self.assertIn("supabase/config.toml", detector)
        self.assertIn(".github/workflows/ci.yml", detector)
        self.assertNotIn("docs/", detector)
        self.assertIn('echo "should-deploy=false"', detector)

    def test_edge_deploy_requires_positive_change_detector_output(self):
        deploy = _job_block(self.workflow, "deploy-edge-functions")

        self.assertIn("edge-function-changes", deploy)
        self.assertIn(
            "needs.edge-function-changes.outputs.should-deploy == 'true'",
            deploy,
        )
        self.assertIn("edge-functions-test", deploy)


if __name__ == "__main__":
    unittest.main()
