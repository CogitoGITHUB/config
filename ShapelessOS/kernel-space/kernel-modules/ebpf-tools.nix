{ config, pkgs, ... }:
{
  # eBPF tools and development packages
  environment.systemPackages = with pkgs; [
    # Core eBPF tools
    bpftrace          # High-level tracing language for eBPF
    bpftools          # Tools for BPF programs
    libbpf            # Library for loading eBPF programs
    
    # Performance analysis
    bcc               # BPF Compiler Collection (Python tools)
    
    # Kernel tracing
    linuxPackages.perf  # Performance monitoring
    trace-cmd         # Kernel tracing
    
    # Development
    clang             # Required for eBPF compilation
    llvm              # LLVM tools for eBPF
    elfutils          # ELF utilities
    
    # Monitoring
    htop
    iotop
    nethogs
  ];
  
  # Enable BPF for unprivileged users (optional, less secure)
  # boot.kernel.sysctl."kernel.unprivileged_bpf_disabled" = 0;
}
