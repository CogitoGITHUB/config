{ config, pkgs, lib, ... }:
{
  # # Enable eBPF support in kernel
  # boot.kernelModules = [
  #   # eBPF requires these
  #   "bpf"
  # ];
  
  # # Kernel parameters for eBPF
  # boot.kernelParams = [
  #   # Enable BPF JIT compiler for better performance
  #   "bpf_jit_enable=1"
  # ];
  
  # # Sysctl for eBPF
  # boot.kernel.sysctl = {
  #   # Enable BPF JIT compiler
  #   "net.core.bpf_jit_enable" = 1;
    
  #   # BPF JIT hardening (set to 0 for debugging, 2 for production)
  #   "net.core.bpf_jit_harden" = 1;
    
  #   # Limit BPF JIT allocations
  #   "net.core.bpf_jit_limit" = 264241152;  # 252 MB
    
  #   # Keep BPF programs loaded (useful for development)
  #   # "kernel.unprivileged_bpf_disabled" = 0;  # Uncomment to allow non-root eBPF
  # };
  
  # # Enable debugfs for BPF (mounted at /sys/kernel/debug)
  # boot.kernel.enable = true;
}
