#!/bin/bash
echo "=== Status dos Headless Clients ==="
echo ""
echo "HC1 (CPU 0):"
pgrep -af "arma3server.*-name=HC1" || echo "  NÃO ESTÁ RODANDO"
taskset -p $(pgrep -f "arma3server.*-name=HC1" 2>/dev/null) 2>/dev/null || echo "  Não foi possível verificar afinidade"

echo ""
echo "HC2 (CPU 1):"
pgrep -af "arma3server.*-name=HC2" || echo "  NÃO ESTÁ RODANDO"
taskset -p $(pgrep -f "arma3server.*-name=HC2" 2>/dev/null) 2>/dev/null || echo "  Não foi possível verificar afinidade"

echo ""
echo "HC3 (CPU 2):"
pgrep -af "arma3server.*-name=HC3" || echo "  NÃO ESTÁ RODANDO"
taskset -p $(pgrep -f "arma3server.*-name=HC3" 2>/dev/null) 2>/dev/null || echo "  Não foi possível verificar afinidade"

echo ""
echo "=== Uso de CPU ==="
top -bn1 | grep "Cpu(s)" || echo "  Não foi possível verificar CPU"