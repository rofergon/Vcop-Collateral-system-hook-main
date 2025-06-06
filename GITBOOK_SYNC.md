# 📚 Sincronización con GitBook

Este documento explica cómo está configurada la sincronización automática entre este repositorio de GitHub y GitBook.

## 🔧 Configuración Actual

### Archivos de Configuración

1. **`.gitbook.yaml`** (raíz del proyecto)
   ```yaml
   root: ./docs/
   structure:
     readme: README.md
     summary: SUMMARY.md
   integrations:
     github:
       enabled: true
   ```

2. **`docs/SUMMARY.md`**
   - Define la estructura completa del libro
   - Organiza los capítulos y secciones
   - Usa enlaces relativos a los archivos markdown

3. **`docs/book.json`**
   - Configuración adicional para plugins
   - Configuración de tema y estilo
   - Configuración de PDF export

## 🚀 Cómo Funciona la Sincronización

### Sincronización Automática
- **Trigger**: Push a la rama `main` o `master`
- **Directorio**: Solo la carpeta `docs/` se sincroniza
- **Tiempo**: ~2-5 minutos después del push
- **Archivos**: Todos los `.md` en la estructura definida

### Estructura Sincronizada
```
docs/
├── README.md (Página de inicio)
├── SUMMARY.md (Índice del libro)
├── GUIA_SISTEMA_OPERATIVO.md
├── architecture/
│   ├── README.md
│   ├── NUEVA_ARQUITECTURA.md
│   └── FLEXIBILIDAD_MAXIMA.md
├── risk-management/
│   ├── README.md
│   └── CALCULOS_RIESGO.md
├── deployment/
│   ├── README.md
│   ├── INSTRUCCIONES_DESPLIEGUE.md
│   ├── SISTEMA_CORREGIDO_DESPLIEGUE.md
│   ├── REFERENCIA_RAPIDA.md
│   ├── TROUBLESHOOTING.md
│   └── PSM-README.md
└── examples/
    └── README.md
```

## ✅ Verificación de Sincronización

### En GitBook
1. Ve a tu espacio en GitBook
2. Revisa que aparezca: "Sincronizado con GitHub"
3. Verifica que la fecha de última sincronización sea reciente

### En GitHub
1. Ve a la pestaña "Actions" (si está habilitada)
2. Revisa que no haya errores en los workflows
3. Verifica que los commits aparezcan en GitBook

## 🛠️ Pasos para Configurar (Si no está configurado)

### 1. En GitBook
1. Ve a tu espacio de GitBook
2. Settings → Integrations
3. Conecta con GitHub
4. Selecciona este repositorio
5. Configura la rama (main/master)
6. Establece `docs/` como directorio root

### 2. En GitHub
1. Ve a Settings → Webhooks
2. Verifica que GitBook tenga acceso
3. Revisa que los permisos sean correctos

## 📝 Reglas para Edición

### Para que la sincronización funcione correctamente:

1. **Siempre edita en GitHub**
   - Los cambios en GitBook pueden perderse
   - GitHub es la fuente de verdad

2. **Mantén la estructura del SUMMARY.md**
   - No muevas archivos sin actualizar enlaces
   - Usa rutas relativas (`./archivo.md`, `../carpeta/archivo.md`)

3. **Commit messages claros**
   - GitBook muestra el historial de cambios
   - Usa mensajes descriptivos

4. **Testa los enlaces**
   - Verifica que todos los enlaces funcionen
   - Usa el preview de GitHub para validar

## 🔄 Flujo de Trabajo Recomendado

### Para Actualizaciones de Documentación

1. **Editar localmente o en GitHub**
   ```bash
   # Clonar el repo
   git clone https://github.com/tu-usuario/vcop-collateral-system.git
   cd vcop-collateral-system
   
   # Editar archivos en docs/
   # ...
   
   # Commit y push
   git add docs/
   git commit -m "docs: actualizar arquitectura del sistema"
   git push origin main
   ```

2. **Verificar en GitBook**
   - Esperar 2-5 minutos
   - Refrescar GitBook
   - Verificar que los cambios aparezcan

3. **Revisar y corregir**
   - Si hay errores, corregir en GitHub
   - Push de nuevo
   - Repetir hasta que esté perfecto

## 🚨 Troubleshooting

### Problemas Comunes

1. **GitBook no se actualiza**
   - Verificar conexión GitHub-GitBook
   - Revisar que el archivo `.gitbook.yaml` esté correcto
   - Check webhook en GitHub Settings

2. **Enlaces rotos**
   - Verificar rutas relativas en `SUMMARY.md`
   - Asegurar que todos los archivos existan
   - Usar el formato correcto: `[Título](ruta/archivo.md)`

3. **Estructura incorrecta**
   - El `SUMMARY.md` define toda la estructura
   - Cualquier archivo no listado ahí no aparecerá
   - Mantener jerarquía consistente con carpetas

### Comandos Útiles

```bash
# Verificar estructura
find docs/ -name "*.md" | sort

# Validar enlaces (si tienes mdbook instalado)
mdbook test docs/

# Preview local
mdbook serve docs/
```

## 📞 Soporte

Si tienes problemas con la sincronización:

1. Revisar la documentación oficial de GitBook
2. Verificar configuración en ambas plataformas  
3. Crear un issue en este repositorio con detalles del problema

## 🔗 Enlaces Útiles

- [GitBook GitHub Integration](https://docs.gitbook.com/integrations/github)
- [GitBook Configuration](https://docs.gitbook.com/publishing/gitbook-configuration)
- [Markdown Guide](https://www.markdownguide.org/) 