import "@typespec/rest";
import "@typespec/http";
import "@azure-tools/typespec-azure-core";
import "@azure-tools/typespec-azure-resource-manager";
import "./scenario.models.tsp";
import "./common.models.tsp";

using TypeSpec.Rest;
using Azure.ResourceManager;
using Azure.Core;
using Azure.Core.Traits;

namespace Microsoft.Chaos;

/**
 * Model that represents the scenario.
 */
@parentResource(Scenario)
model ScenarioConfiguration
  is Azure.ResourceManager.ProxyResource<ScenarioConfigurationProperties> {
  ...ResourceNameParameter<
    Resource = ScenarioConfiguration,
    KeyName = "scenarioConfigurationName",
    SegmentName = "configurations",
    NamePattern = "^[^<>%&:?#/\\\\]+$"
  >;
}

/**
 * Model that represents the properties of the scenario configuration.
 */
model ScenarioConfigurationProperties {
  /**
   * Resource ID of the scenario this configuration applies to.
   */
  @pattern("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Chaos/workspaces/[^/]+/scenarios/[^/]+$")
  scenarioId: string;

  /**
   * Runtime parameter values for the scenario. Keys must match parameter names defined in the scenario.
   */
  @identifiers(#["key"])
  parameters?: KeyValuePair[];

  /**
   * Exclusion criteria for protecting resources from fault injection.
   */
  exclusions?: ConfigurationExclusions;

  /**
   * Most recent provisioning state for the given scenario resource.
   */
  @visibility(Lifecycle.Read)
  provisioningState?: ProvisioningState;
}

/**
 * Model that represents exclusion criteria for protecting resources from fault injection.
 * Uses union (OR) logic - a resource is excluded if it matches ANY criteria.
 */
model ConfigurationExclusions {
  /**
   * Array of specific resource IDs to exclude from fault injection.
   */
  resources?: string[];

  /**
   * Array of tag key-value pairs. Resources with matching tags are excluded.
   */
  @identifiers(#["key"])
  tags?: KeyValuePair[];

  /**
   * Array of resource types. All resources of these types are excluded.
   */
  types?: string[];
}

@parentResource(ScenarioConfiguration)
@singleton("latest")
model Validation is ProxyResource<ValidationProperties> {
  ...ResourceNameParameter<Validation>;
}

/**
 * Model that represents the properties of the scenario validation.
 */
#suppress "@azure-tools/typespec-azure-resource-manager/arm-resource-provisioning-state" "kinda resource"
model ValidationProperties {
  /**
   * The scenario validation state.
   */
  @visibility(Lifecycle.Read)
  @lroStatus
  state: ScenarioValidationState;

  /**
   * The scenario validation UTC start time.
   */
  @visibility(Lifecycle.Read)
  startedAt: utcDateTime;

  /**
   * Execution plan created from validation. This plan will be executed as-is on next scenario execution.
   */
  executionPlanJson?: string;

  /**
   * The scenario validation UTC end time.
   */
  @visibility(Lifecycle.Read)
  completedAt: utcDateTime;

  /**
   * The scenario validation errors, if present.
   */
  errors?: ScenarioErrors;
}

/**
 * Model that represents the scenario run result.
 */
model ScenarioRunResult {
  /**
   * The resource id of the latest scenario run.
   */
  @visibility(Lifecycle.Read)
  runResourceId: string;

  /**
   * The time when the last scenario run was started.
   */
  @visibility(Lifecycle.Read)
  startedAt: utcDateTime;
}

/**
 * Model that represents the scenario run errors.
 */
model ScenarioErrors {
  /**
   * Error code for internal server errors.
   */
  errorCode?: string;

  /**
   * Error message for internal server errors.
   */
  errorMessage?: string;

  /**
   * Any permission errors associated with the scenario run.
   */
  @visibility(Lifecycle.Read)
  @identifiers(#["resourceId"])
  permission: PermissionError[];

  /**
   * Any resource state errors associated with the scenario run.
   */
  @visibility(Lifecycle.Read)
  @identifiers(#["resourceId"])
  resource: ResourceStateError[];
}

/**
 * Model that represents the permission error.
 */
model PermissionError {
  /**
   * The resource id for the affected resource.
   */
  @visibility(Lifecycle.Read)
  resourceId: string;

  /**
   * The missing permissions.
   */
  @visibility(Lifecycle.Read)
  missingPermissions: string[];

  /**
   * The required permissions.
   */
  @visibility(Lifecycle.Read)
  requiredPermissions: string[];

  /**
   * The recommended roles.
   */
  @visibility(Lifecycle.Read)
  recommendedRoles: string[];

  /**
   * The identity.
   */
  @visibility(Lifecycle.Read)
  identity?: EntraIdentity;
}

/**
 * Model that represents the Azure Entra identity.
 */
model EntraIdentity {
  /**
   * The identity object id.
   */
  @visibility(Lifecycle.Read)
  objectId: string;

  /**
   * The identity tenant id.
   */
  @visibility(Lifecycle.Read)
  tenantId: string;
}

/**
 * Model that represents the resource state error.
 */
model ResourceStateError {
  /**
   * The resource id for the affected resource.
   */
  @visibility(Lifecycle.Read)
  resourceId: string;

  /**
   * The error code.
   */
  @visibility(Lifecycle.Read)
  errorCode: int32;

  /**
   * The error message.
   */
  @visibility(Lifecycle.Read)
  errorMessage: string;

  /**
   * The remediation uri.
   */
  @visibility(Lifecycle.Read)
  remediationUri: string;
}

/**
 * Enum of the scenario validation state.
 */
union ScenarioValidationState {
  string,

  /**
   * The scenario validation is in a resolving state.
   */
  Resolving: "Resolving",

  /**
   * The scenario validation is in a generating state.
   */
  Generating: "Generating",

  /**
   * The scenario validation is in a validating state.
   */
  Validating: "Validating",

  /**
   * The scenario validation has been accepted.
   */
  Accepted: "Accepted",

  /**
   * The scenario validation has not yet started.
   */
  NotStarted: "NotStarted",

  /**
   * The scenario validation reflects a state that requires attention.
   * This is a terminal failure state indicating validation issues were found.
   */
  @lroFailed
  RequiresAttention: "RequiresAttention",

  /**
   * The scenario validation found no valid resources to perform fault behaviors against.
   * This is a terminal failure state.
   */
  @lroFailed
  NoResolvedResources: "NoResolvedResources",

  /**
   * The scenario validation completed successfully and the scenario is ready to execute.
   */
  @lroSucceeded
  Succeeded: "Succeeded",
}

/**
 * Model that represents a list of scenario configurations and a link for pagination.
 */
model ScenarioConfigurationListResult is Azure.Core.Page<ScenarioConfiguration>;
