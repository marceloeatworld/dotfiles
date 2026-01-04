# Software Defined Radio (SDR) and Radio Tools
# For use with RTL-SDR, HackRF, Airspy, and other SDR devices
#
# SkyRoof: Install in Windows VM (Windows-only for satellite tracking)
# Linux tools: SDR++, GQRX, GNU Radio
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── SDR Receivers ──
    sdrpp              # SDR++ - Modern, cross-platform SDR receiver (recommended)
    gqrx               # GQRX - Classic SDR receiver based on GNU Radio

    # ── SDR Drivers & Libraries ──
    rtl-sdr            # RTL-SDR drivers and tools (rtl_test, rtl_fm, rtl_tcp, etc.)
    soapysdr           # Hardware abstraction layer for SDR devices
    soapyrtlsdr        # SoapySDR plugin for RTL-SDR

    # ── Signal Processing ──
    gnuradio           # GNU Radio - Full SDR framework for signal processing

    # ── Utilities ──
    kalibrate-rtl      # Calibrate RTL-SDR frequency offset using GSM signals

    # ── Audio for demodulation ──
    sox                # Sound processing (convert audio formats)
    audacity           # Audio editor (analyze demodulated signals)
  ];
}
