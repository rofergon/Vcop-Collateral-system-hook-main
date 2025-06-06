# 📋 Instrucciones para Despliegue del Sistema VCOP

> **⚠️ IMPORTANTE**: Para el sistema de **préstamos colateralizados corregido**, consulta la nueva guía:  
> 📄 **[SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md)**

---

## 🚀 Sistema de Préstamos Colateralizados (Actualizado)

### **Comando Simplificado (Recomendado)**
```bash
# Despliegue completo automatizado del sistema corregido
make deploy-corrected-system
```

### **Workflow Completo Automatizado**
```bash
# Despliega + Configura + Prueba automáticamente
make deploy-and-auto-test
```

### **Verificación del Sistema**
```bash
# Test del sistema desplegado
make test-corrected-system
```

---

## 🔧 Sistema VCOP Original (Legacy)

Para ejecutar el despliegue del sistema VCOP original en dos partes, siga estos pasos:

### **1. Desplegar Contratos Base**

```bash
forge script script/DeployVCOPBase.sol:DeployVCOPBase --via-ir --broadcast --fork-url https://sepolia.base.org
```

Este comando desplegará:
- USDC simulado
- Token VCOP
- Oráculo VCOP
- Collateral Manager

### **2. Configurar el Sistema**

```bash
forge script script/ConfigureVCOPSystem.sol:ConfigureVCOPSystem --via-ir --broadcast --fork-url https://sepolia.base.org
```

Este segundo comando configurará:
- El hook de Uniswap v4
- Las referencias cruzadas entre contratos
- Los colaterales y parámetros del sistema
- El pool de Uniswap v4 y la liquidez inicial
- El módulo de estabilidad del precio (PSM)

### **Ventajas de esta separación**

1. **Mayor seguridad**: Se reduce el riesgo de problemas con las claves privadas al limitar el alcance de cada script.
2. **Mejor recuperación ante errores**: Si hay un problema en la segunda parte, no es necesario redesplegar todos los contratos.
3. **Claridad del código**: Cada script tiene una responsabilidad bien definida.
4. **Control de permisos**: El segundo script verifica los propietarios antes de proceder con la configuración.

---

## 📚 Documentación Relacionada

- 📄 **[SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md)** - Guía completa del sistema corregido
- 📄 **[PSM-README.md](./PSM-README.md)** - Configuración del Peg Stability Module
- 📄 **[README.md](./README.md)** - Documentación general de despliegue

---

## 🎯 Sistemas Disponibles

| Sistema | Comando | Estado | Documentación |
|---------|---------|--------|---------------|
| **Préstamos Colateralizados** | `make deploy-corrected-system` | ✅ **Activo** | [SISTEMA_CORREGIDO_DESPLIEGUE.md](./SISTEMA_CORREGIDO_DESPLIEGUE.md) |
| VCOP Original | Scripts manuales | 🔄 Legacy | Esta página |
| PSM Module | Ver PSM-README.md | 📋 Documentado | [PSM-README.md](./PSM-README.md) | 