#!/bin/bash
# Script para ejecutar los diferentes tipos de pruebas

echo "==============================================="
echo "    IOT Controller - Testing Suite"
echo "==============================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ "$1" = "unit" ]; then
    echo -e "${BLUE}Ejecutando Pruebas Unitarias...${NC}"
    flutter test test/unit/smart_home_state_test.dart -v
    
elif [ "$1" = "widget" ]; then
    echo -e "${BLUE}Ejecutando Pruebas de Widget...${NC}"
    flutter test test/widget/profiles_screen_widget_test.dart -v
    
elif [ "$1" = "integration" ]; then
    echo -e "${BLUE}Ejecutando Pruebas E2E/Integración...${NC}"
    flutter test test/integration/smart_home_integration_test.dart -v
    
elif [ "$1" = "all" ]; then
    echo -e "${BLUE}Ejecutando TODAS las Pruebas...${NC}"
    flutter test -v
    
elif [ "$1" = "coverage" ]; then
    echo -e "${BLUE}Ejecutando Pruebas con Coverage...${NC}"
    flutter test --coverage
    echo -e "${GREEN}Reporte generado en: coverage/lcov.info${NC}"
    
elif [ "$1" = "quick" ]; then
    echo -e "${BLUE}Ejecutando Pruebas Rápidas (sin verbose)...${NC}"
    flutter test
    
else
    echo -e "${YELLOW}Uso:${NC}"
    echo "  $0 unit          - Ejecutar pruebas unitarias"
    echo "  $0 widget        - Ejecutar pruebas de widget"
    echo "  $0 integration   - Ejecutar pruebas E2E"
    echo "  $0 all           - Ejecutar todas las pruebas (verbose)"
    echo "  $0 coverage      - Ejecutar con cobertura"
    echo "  $0 quick         - Ejecución rápida sin verbose"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "  ./run_tests.sh unit"
    echo "  ./run_tests.sh all"
    echo "  ./run_tests.sh coverage"
fi
