#pragma once

#include <optional>

namespace manifolding::services::sensorslib {

void ensureInit();

[[nodiscard]] std::optional<double> cpuPackageTemp();
[[nodiscard]] std::optional<double> gpuPciAverageTemp();

} // namespace manifolding::services::sensorslib
