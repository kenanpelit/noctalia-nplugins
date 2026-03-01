function parseJsonArray(output) {
  if (!output) return [];

  var trimmed = String(output).trim();
  if (!trimmed) return [];

  try {
    var parsed = JSON.parse(trimmed);
    if (Array.isArray(parsed)) return parsed;
    if (parsed && typeof parsed === "object") return [parsed];
  } catch (e) {
    // Fall back to JSON-lines.
  }

  var lines = trimmed.split("\n");
  var results = [];
  lines.forEach(function(line) {
    var item = String(line).trim();
    if (!item) return;
    try {
      results.push(JSON.parse(item));
    } catch (e) {
      console.warn("NPodman: failed to parse line", e);
    }
  });
  return results;
}

function shortId(id) {
  return String(id || "").substring(0, 12);
}

function normalizeName(value) {
  if (Array.isArray(value)) return value.join(", ");
  return String(value || "");
}

function normalizePortEntry(entry) {
  if (entry === null || entry === undefined) return "";
  if (typeof entry === "string") return entry;
  if (typeof entry !== "object") return String(entry);

  var hostIp = entry.host_ip || entry.HostIP || entry.hostIp || entry.hostIP || "";
  var hostPort = entry.host_port || entry.HostPort || entry.hostPort || "";
  var containerPort = entry.container_port || entry.ContainerPort || entry.containerPort || "";
  var protocol = entry.protocol || entry.Protocol || entry.type || entry.Type || "";
  var range = entry.range || entry.Range || "";

  var left = "";
  if (hostIp) left = String(hostIp);
  if (hostPort) left += (left ? ":" : "") + String(hostPort);

  var right = "";
  if (containerPort) right = String(containerPort);
  if (!right && range) right = String(range);
  if (protocol) right += (right ? "/" : "") + String(protocol).toLowerCase();

  if (left && right) return left + " -> " + right;
  if (right) return right;
  if (left) return left;

  var fallback = [];
  ["host_ip", "HostIP", "host_port", "HostPort", "container_port", "ContainerPort", "protocol", "Protocol"].forEach(function(key) {
    if (entry[key] !== undefined && entry[key] !== null && String(entry[key]) !== "") {
      fallback.push(String(entry[key]));
    }
  });
  return fallback.join(" ");
}

function formatPorts(value) {
  if (value === null || value === undefined) return "";
  if (typeof value === "string") return value;

  if (Array.isArray(value)) {
    return value.map(normalizePortEntry).filter(function(item) {
      return String(item).trim() !== "";
    }).join(", ");
  }

  if (typeof value === "object") {
    if (value.container_port !== undefined || value.ContainerPort !== undefined) {
      return normalizePortEntry(value);
    }

    var mapped = Object.keys(value).map(function(key) {
      var normalized = normalizePortEntry(value[key]);
      return normalized || key;
    }).filter(function(item) {
      return String(item).trim() !== "";
    });
    return mapped.join(", ");
  }

  return String(value);
}

function normalizeStateKey(state) {
  var text = String(state || "").trim().toLowerCase();
  if (!text) return "unknown";

  var first = text.split(/[\s(]/)[0];
  if (!first) return "unknown";
  if (first === "up") return "running";
  return first;
}

function statusColor(state) {
  switch (normalizeStateKey(state)) {
    case "running":
      return "#4caf50";
    case "created":
    case "configured":
      return "#2196f3";
    case "paused":
    case "degraded":
    case "restarting":
    case "stopping":
      return "#ff9800";
    case "exited":
    case "stopped":
      return "#f44336";
    default:
      return "#9e9e9e";
  }
}

function isRunningState(state) {
  return normalizeStateKey(state) === "running";
}

function canStartState(state) {
  return ["configured", "created", "exited", "stopped", "initialized"].indexOf(normalizeStateKey(state)) !== -1;
}

function canStopState(state) {
  return ["running", "paused", "degraded"].indexOf(normalizeStateKey(state)) !== -1;
}

function canRestartState(state) {
  return ["running", "paused", "degraded", "configured", "created", "exited", "stopped"].indexOf(normalizeStateKey(state)) !== -1;
}

function parseContainers(output) {
  return parseJsonArray(output).map(function(container) {
    var rawState = String(container.State || container.Status || "unknown");
    var stateKey = normalizeStateKey(rawState);
    var names = normalizeName(container.Names || container.Namespaces || container.Name);
    return {
      uid: String(container.Id || container.ID || ""),
      shortId: shortId(container.Id || container.ID || ""),
      name: names,
      image: String(container.Image || container.ImageName || ""),
      state: stateKey,
      status: String(container.Status || rawState || ""),
      ports: formatPorts(container.Ports || container.PortMappings || []),
      running: isRunningState(rawState),
      canStart: canStartState(rawState),
      canStop: canStopState(rawState),
      canRestart: canRestartState(rawState),
      statusColor: statusColor(rawState)
    };
  });
}

function parseImages(output) {
  return parseJsonArray(output).map(function(image) {
    return {
      uid: String(image.Id || image.ID || ""),
      shortId: shortId(image.Id || image.ID || ""),
      repository: String(image.Repository || image.RepositoryName || "<none>"),
      tag: String(image.Tag || "latest"),
      size: String(image.Size || image.VirtualSize || ""),
      created: String(image.CreatedAt || image.Created || "")
    };
  });
}

function parsePods(output) {
  return parseJsonArray(output).map(function(pod) {
    var rawState = String(pod.Status || pod.State || "unknown");
    return {
      uid: String(pod.Id || pod.ID || ""),
      shortId: shortId(pod.Id || pod.ID || ""),
      name: String(pod.Name || ""),
      status: normalizeStateKey(rawState),
      containers: String(pod.NumberOfContainers || pod.Containers || "0"),
      running: isRunningState(rawState),
      canStart: canStartState(rawState),
      canStop: canStopState(rawState),
      canRestart: canRestartState(rawState),
      statusColor: statusColor(rawState)
    };
  });
}
