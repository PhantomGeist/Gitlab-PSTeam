---
stage: Govern
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Scan result policies **(ULTIMATE ALL)**

> Group-level scan result policies [introduced](https://gitlab.com/groups/gitlab-org/-/epics/7622) in GitLab 15.6.

You can use scan result policies to take action based on scan results. For example, one type of scan
result policy is a security approval policy that allows approval to be required based on the
findings of one or more security scan jobs. Scan result policies are evaluated after a CI scanning job is fully executed.

NOTE:
Scan result policies are applicable only to [protected](../../project/protected_branches.md) target branches.

NOTE:
When a protected branch is created or deleted, the policy approval rules synchronize, with a delay of 1 minute.

The following video gives you an overview of GitLab scan result policies:

<div class="video-fallback">
  See the video: <a href="https://youtu.be/w5I9gcUgr9U">Overview of GitLab Scan Result Policies</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/w5I9gcUgr9U" frameborder="0" allowfullscreen> </iframe>
</figure>

## Merge request with multiple pipelines

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/379108) in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `multi_pipeline_scan_result_policies`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/409482) in GitLab 16.3.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `multi_pipeline_scan_result_policies`. On GitLab.com, this feature is available.

A project can have multiple pipeline types configured. A single commit can initiate multiple
pipelines, each of which may contain a security scan.

- In GitLab 16.3 and later, the results of all completed pipelines for the latest commit in
the merge request's source and target branch are evaluated and used to enforce the scan result policy.
Parent-child pipelines and on-demand DAST pipelines are not considered.
- In GitLab 16.2 and earlier, only the results of the latest completed pipeline were evaluated
when enforcing scan result policies.

## Scan result policy editor

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77814) in GitLab 14.8.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/369473) in GitLab 15.6.

NOTE:
Only project Owners have the [permissions](../../permissions.md#project-members-permissions)
to select Security Policy Project.

Once your policy is complete, save it by selecting **Configure with a merge request** at the bottom of the
editor. This redirects you to the merge request on the project's configured security policy project.
If a security policy project doesn't link to your project, GitLab creates such a project for you.
Existing policies can also be removed from the editor interface by selecting **Delete policy** at
the bottom of the editor.

Most policy changes take effect as soon as the merge request is merged. Any changes that
do not go through a merge request and are committed directly to the default branch may require up to 10 minutes
before the policy changes take effect.

The [policy editor](index.md#policy-editor) supports YAML mode and rule mode.

NOTE:
Propagating scan result policies created for groups with a large number of projects take a while to complete.

## Scan result policies schema

The YAML file with scan result policies consists of an array of objects matching the scan result
policy schema nested under the `scan_result_policy` key. You can configure a maximum of five
policies under the `scan_result_policy` key.

When you save a new policy, GitLab validates its contents against [this JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json).
If you're not familiar with how to read [JSON schemas](https://json-schema.org/),
the following sections and tables provide an alternative.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `scan_result_policy` | `array` of Scan Result Policy | true |  | List of scan result policies (maximum 5). |

## Scan result policy schema

> The `approval_settings` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418752) in GitLab 16.4 [with a flag](../../../administration/feature_flags.md) named `scan_result_any_merge_request`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `scan_result_any_merge_request`.
On GitLab.com, this feature is not available.

| Field | Type | Required |Possible values | Description |
|-------|------|----------|----------------|-------------|
| `name` | `string` | true |  | Name of the policy. Maximum of 255 characters.|
| `description` (optional) | `string` | true |  | Description of the policy. |
| `enabled` | `boolean` | true | `true`, `false` | Flag to enable (`true`) or disable (`false`) the policy. |
| `rules` | `array` of rules | true |  | List of rules that the policy applies. |
| `actions` | `array` of actions | false|  | List of actions that the policy enforces. |
| `approval_settings` | `object` | false | `{prevent_approval_by_author: boolean, prevent_approval_by_commit_author: boolean, remove_approvals_with_new_commit: boolean, require_password_to_approve: boolean}` | Project settings that the policy overrides. |

## `scan_finding` rule type

> - The scan result policy field `vulnerability_attributes` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123052) in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `enforce_vulnerability_attributes_rules`. [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/418784) in GitLab 16.3. Feature flag `enforce_vulnerability_attributes_rules` removed in GitLab 16.5.
> - The scan result policy field `vulnerability_age` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123956) in GitLab 16.2.
> - The `branch_exceptions` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`. Generally available in GitLab 16.5. Feature flag removed.

FLAG:
On self-managed GitLab, by default the `branch_exceptions` field is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`.
On GitLab.com, this feature is available.

This rule enforces the defined actions based on security scan findings.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `scan_finding` | The rule's type. |
| `branches` | `array` of `string` | true if `branch_type` field does not exist | `[]` or the branch's name | Applicable only to protected target branches. An empty array, `[]`, applies the rule to all protected target branches. Cannot be used with the `branch_type` field. |
| `branch_type` | `string` | true if `branches` field does not exist | `default` or `protected` | The types of branches the given policy applies to. Cannot be used with the `branches` field. |
| `branch_exceptions` | `array` of `string` | false |  Names of branches | Branches to exclude from this rule. |
| `scanners` | `array` of `string` | true | `sast`, `secret_detection`, `dependency_scanning`, `container_scanning`, `dast`, `coverage_fuzzing`, `api_fuzzing` | The security scanners for this rule to consider. `sast` includes results from both SAST and SAST IaC scanners. |
| `vulnerabilities_allowed` | `integer` | true | Greater than or equal to zero | Number of vulnerabilities allowed before this rule is considered. |
| `severity_levels` | `array` of `string` | true | `info`, `unknown`, `low`, `medium`, `high`, `critical` | The severity levels for this rule to consider. |
| `vulnerability_states` | `array` of `string` | true | `newly_detected`, `detected`, `confirmed`, `resolved`, `dismissed`, `new_needs_triage`, `new_dismissed` | All vulnerabilities fall into two categories:<br><br>**Newly Detected Vulnerabilities** - the `newly_detected` policy option covers vulnerabilities identified in the merge request branch itself but that do not currently exist on the default branch. This policy option requires a pipeline to complete before the rule is evaluated so that it knows whether vulnerabilities are newly detected or not. Merge requests are blocked until the pipeline and necessary security scans are complete. The `newly_detected` option considers both of the following statuses:<br><br> • Detected<br> • Dismissed<br><br> The `new_needs_triage` option considers the status<br><br> • Detected<br><br> The `new_dismissed` option considers the status<br><br> • Dismissed<br><br>**Pre-Existing Vulnerabilities** - these policy options are evaluated immediately and do not require a pipeline complete as they consider only vulnerabilities previously detected in the default branch.<br><br> • `Detected` - the policy looks for vulnerabilities in the detected state.<br> • `Confirmed` - the policy looks for vulnerabilities in the confirmed state.<br> • `Dismissed` - the policy looks for vulnerabilities in the dismissed state.<br> • `Resolved` - the policy looks for vulnerabilities in the resolved state. |
| `vulnerability_attributes` | `object` | false | `{false_positive: boolean, fix_available: boolean}` | All vulnerability findings are considered by default. But filters can be applied for attributes to consider only vulnerability findings: <br><br> • With a fix available (`fix_available: true`)<br><br> • With no fix available (`fix_available: false`)<br> • That are false positive (`false_positive: true`)<br> • That are not false positive (`false_positive: false`)<br> • Or a combination of both. For example (`fix_available: true, false_positive: false`) |
| `vulnerability_age` | `object` | false | N/A | Filter pre-existing vulnerability findings by age. A vulnerability's age is calculated as the time since it was detected in the project. The criteria are `operator`, `value`, and  `interval`.<br>- The `operator` criterion specifies if the age comparison used is older than (`greater_than`) or younger than (`less_than`).<br>- The `value` criterion specifies the numeric value representing the vulnerability's age.<br>- The `interval` criterion specifies the unit of measure of the vulnerability's age: `day`, `week`, `month`, or `year`.<br><br>Example: `operator: greater_than`, `value: 30`, `interval: day`. |

## `license_finding` rule type

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8092) in GitLab 15.9 [with a flag](../../../administration/feature_flags.md) named `license_scanning_policies`.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/397644) in GitLab 15.11. Feature flag `license_scanning_policies` removed.
> - The `branch_exceptions` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`. Enabled by default.

FLAG:
On self-managed GitLab, by default the `branch_exceptions` field is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`.
On GitLab.com, this feature is available.

This rule enforces the defined actions based on license findings.

| Field      | Type | Required | Possible values | Description |
|------------|------|----------|-----------------|-------------|
| `type` | `string` | true | `license_finding` | The rule's type. |
| `branches` | `array` of `string` | true if `branch_type` field does not exist | `[]` or the branch's name | Applicable only to protected target branches. An empty array, `[]`, applies the rule to all protected target branches. Cannot be used with the `branch_type` field. |
| `branch_type` | `string` | true if `branches` field does not exist | `default` or `protected` | The types of branches the given policy applies to. Cannot be used with the `branches` field. |
| `branch_exceptions` | `array` of `string` | false |  Names of branches | Branches to exclude from this rule. |
| `match_on_inclusion` | `boolean` | true | `true`, `false` | Whether the rule matches inclusion or exclusion of licenses listed in `license_types`. |
| `license_types` | `array` of `string` | true | license types | [SPDX license names](https://spdx.org/licenses) to match on, for example `Affero General Public License v1.0` or `MIT License`. |
| `license_states` | `array` of `string` | true | `newly_detected`, `detected` | Whether to match newly detected and/or previously detected licenses. The `newly_detected` state triggers approval when either a new package is introduced or when a new license for an existing package is detected. |

## `any_merge_request` rule type

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418752) in GitLab 16.4.
> - The `branch_exceptions` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`. Enabled by default.

FLAG:
On self-managed GitLab, by default the `branch_exceptions` field is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `security_policies_branch_exceptions`.
On GitLab.com, this feature is available.

This rule enforces the defined actions for any merge request based on the commits signature.

| Field         | Type                | Required                                   | Possible values           | Description                                                                                                                                                         |
|---------------|---------------------|--------------------------------------------|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`        | `string`            | true                                       | `any_merge_request`       | The rule's type. |
| `branches`    | `array` of `string` | true if `branch_type` field does not exist | `[]` or the branch's name | Applicable only to protected target branches. An empty array, `[]`, applies the rule to all protected target branches. Cannot be used with the `branch_type` field. |
| `branch_type` | `string`            | true if `branches` field does not exist    | `default` or `protected`  | The types of branches the given policy applies to. Cannot be used with the `branches` field. |
| `branch_exceptions` | `array` of `string` | false |  Names of branches | Branches to exclude from this rule. |
| `commits`     | `string`            | true                                       | `any`, `unsigned`         | Whether the rule matches for any commits, or only if unsigned commits are detected in the merge request. |

## `require_approval` action type

This action sets an approval rule to be required when conditions are met for at least one rule in
the defined policy.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `require_approval` | The action's type. |
| `approvals_required` | `integer` | true | Greater than or equal to zero | The number of MR approvals required. |
| `user_approvers` | `array` of `string` | false | Username of one of more users | The users to consider as approvers. Users must have access to the project to be eligible to approve. |
| `user_approvers_ids` | `array` of `integer` | false | ID of one of more users | The IDs of users to consider as approvers. Users must have access to the project to be eligible to approve. |
| `group_approvers` | `array` of `string` | false | Path of one of more groups | The groups to consider as approvers. Users with [direct membership in the group](../../project/merge_requests/approvals/rules.md#group-approvers) are eligible to approve. |
| `group_approvers_ids` | `array` of `integer` | false | ID of one of more groups | The IDs of groups to consider as approvers. Users with [direct membership in the group](../../project/merge_requests/approvals/rules.md#group-approvers) are eligible to approve. |
| `role_approvers` | `array` of `string` | false | One or more [roles](../../../user/permissions.md#roles) (for example: `owner`, `maintainer`)  | The roles to consider as approvers that are eligible to approve. |

Requirements and limitations:

- You must add the respective [security scanning tools](../index.md#application-coverage).
  Otherwise, scan result policies do not have any effect.
- The maximum number of policies is five.
- Each policy can have a maximum of five rules.
- All configured scanners must be present in the merge request's latest pipeline. If not, approvals are required even if some vulnerability criteria have not been met.

## Example security scan result policies project

You can use this example in a `.gitlab/security-policies/policy.yml` file stored in a
[security policy project](index.md#security-policy-project):

```yaml
---
scan_result_policy:
- name: critical vulnerability CS approvals
  description: critical severity level only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 0
    severity_levels:
    - critical
    vulnerability_states:
    - newly_detected
    vulnerability_attributes:
      false_positive: true
      fix_available: true
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
    - adalberto.dare
- name: secondary CS approvals
  description: secondary only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
    - low
    - unknown
    vulnerability_states:
    - detected
    vulnerability_age:
      operator: greater_than
      value: 30
      interval: day
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - owner
```

In this example:

- Every MR that contains new `critical` vulnerabilities identified by container scanning requires
  one approval from `alberto.dare`.
- Every MR that contains more than one preexisting `low` or `unknown` vulnerability older than 30 days identified by
  container scanning requires one approval from a project member with the Owner role.

## Example for Scan Result Policy editor

You can use this example in the YAML mode of the [Scan Result Policy editor](#scan-result-policy-editor).
It corresponds to a single object from the previous example:

```yaml
type: scan_result_policy
name: critical vulnerability CS approvals
description: critical severity level only for container scanning
enabled: true
rules:
- type: scan_finding
  branches:
  - main
  scanners:
  - container_scanning
  vulnerabilities_allowed: 1
  severity_levels:
  - critical
  vulnerability_states:
  - newly_detected
actions:
- type: require_approval
  approvals_required: 1
  user_approvers:
  - adalberto.dare
```

## Understanding scan result policy approvals

### Scope of scan result policy comparison

- To determine when approval is required on a merge request, we compare the latest completed pipelines for each supported pipeline source for the source and target branch (for example, `feature`/`main`). This ensures the most comprehensive evaluation of scan results.
- We compare findings from the latest completed pipelines that ran on `HEAD` of the source and target branch.
- Scan result policies considers all supported pipeline sources (based on the [`CI_PIPELINE_SOURCE` variable](../../../ci/variables/predefined_variables.md)) when comparing results from both the source and target branches when determining if a merge request requires approval. Pipeline sources `webide` and `parent_pipeline` are not supported.

### Accepting risk and ignoring vulnerabilities in future merge requests

For scan result policies that are scoped to `newly_detected` findings, it's important to understand the implications of this vulnerability state. A finding is considered `newly_detected` if it exists on the merge request's branch but not on the default branch. When a merge request whose branch contains `newly_detected` findings is approved and merged, approvers are "accepting the risk" of those vulnerabilities. If one or more of the same vulnerabilities were detected after this time, their status would be `previously_detected` and so not be out of scope of a policy aimed at `newly_detected` findings. For example:

- A scan result policy is created to block critical SAST findings. If a SAST finding for CVE-1234 is approved, future merge requests with the same violation will not require approval in the project.

When using license approval policies, the combination of project, component (dependency), and license are considered in the evaluation. If a license is approved as an exception, future merge requests don't require approval for the same combination of project, component (dependency), and license. The component's version is not be considered in this case. If a previously approved package is updated to a new version, approvers will not need to re-approve. For example:

- A license approval policy is created to block merge requests with newly detected licenses matching `AGPL-1.0`. A change is made in project `demo` for component `osframework` that violates the policy. If approved and merged, future merge requests to `osframework` in project `demo` with the license `AGPL-1.0` don't require approval.

### Multiple approvals

There are several situations where the scan result policy requires an additional approval step. For example:

- The number of security jobs is reduced in the working branch and no longer matches the number of
  security jobs in the target branch. Users can't skip the Scanning Result Policies by removing
  scanning jobs from the CI/CD configuration. Only the security scans that are configured in the
  scan result policy rules are checked for removal.

  For example, consider a situation where the default branch pipeline has four security scans:
  `sast`, `secret_detection`, `container_scanning`, and `dependency_scanning`. A scan result
  policy enforces two scanners: `container_scanning` and `dependency_scanning`. If an MR removes a
  scan that is configured in scan result policy, `container_scanning` for example, an additional
  approval is required.
- Someone stops a pipeline security job, and users can't skip the security scan.
- A job in a merge request fails and is configured with `allow_failure: false`. As a result, the pipeline is in a blocked state.
- A pipeline has a manual job that must run successfully for the entire pipeline to pass.

### Known issues

We have identified in [epic 11020](https://gitlab.com/groups/gitlab-org/-/epics/11020) common areas of confusion in scan result findings that need to be addressed. Below are a few of the known issues:

- When using `newly_detected`, some findings may require approval when they are not introduced by the merge request (such as a new CVE on a related dependency). We currently use `main tip` of the target branch for comparison. In the future, we plan to use `merge base` for `newly_detected` policies (see [issue 428518](https://gitlab.com/gitlab-org/gitlab/-/issues/428518)).
- Findings or errors that cause approval to be required on a scan result policy may not be evident in the Security MR Widget. By using `merge base` in [issue 428518](https://gitlab.com/gitlab-org/gitlab/-/issues/428518) some cases will be addressed. We will additionally be [displaying more granular details](https://gitlab.com/groups/gitlab-org/-/epics/11185) about what caused security policy violations.
- Security policy violations are distinct compared to findings displayed in the MR widgets. Some violations may not be present in the MR widget. We are working to harmonize our features in [epic 11020](https://gitlab.com/groups/gitlab-org/-/epics/11020) and to display policy violations explicitly in merge requests in [epic 11185](https://gitlab.com/groups/gitlab-org/-/epics/11185).
