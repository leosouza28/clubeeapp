#!/usr/bin/env python3
"""
Script para criar ícones de exemplo para demonstração
Uso: python3 scripts/create_example_icons.py [guara|vale_das_minas]
"""

import sys
import os
from pathlib import Path

def create_icon_with_text(client_name, color, letter, size=(1024, 1024)):
    """Cria um ícone simples com texto"""
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("❌ PIL não está instalado. Execute: pip install Pillow")
        return False
    
    # Configurações por cliente
    configs = {
        'guara': {
            'color': (25, 118, 210, 255),  # #1976D2
            'letter': 'G',
            'name': 'Guará Park'
        },
        'vale_das_minas': {
            'color': (76, 175, 80, 255),   # #4CAF50
            'letter': 'V',
            'name': 'Vale das Minas'
        }
    }
    
    if client_name not in configs:
        print(f"❌ Cliente '{client_name}' não reconhecido")
        return False
    
    config = configs[client_name]
    
    # Criar pasta de ícones
    icon_dir = f"assets/icons/{client_name if client_name != 'vale_das_minas' else 'valedasminas'}"
    Path(icon_dir).mkdir(parents=True, exist_ok=True)
    
    # Criar ícone principal
    img = Image.new('RGBA', size, config['color'])
    draw = ImageDraw.Draw(img)
    
    # Tentar usar fonte do sistema
    try:
        if sys.platform == 'darwin':  # macOS
            font_path = '/System/Library/Fonts/Arial.ttf'
        elif sys.platform == 'win32':  # Windows
            font_path = 'C:/Windows/Fonts/arial.ttf'
        else:  # Linux
            font_path = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
        
        font = ImageFont.truetype(font_path, int(size[0] * 0.4))
    except:
        font = ImageFont.load_default()
    
    # Calcular posição do texto
    bbox = draw.textbbox((0, 0), config['letter'], font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (size[0] - text_width) // 2
    y = (size[1] - text_height) // 2 - bbox[1]
    
    # Desenhar texto
    draw.text((x, y), config['letter'], fill='white', font=font)
    
    # Salvar ícone principal
    icon_path = f"{icon_dir}/icon.png"
    img.save(icon_path)
    print(f"✅ Ícone principal criado: {icon_path}")
    
    # Criar ícone adaptativo (menor, só a letra)
    adaptive_img = Image.new('RGBA', (432, 432), (0, 0, 0, 0))  # Transparente
    adaptive_draw = ImageDraw.Draw(adaptive_img)
    
    try:
        adaptive_font = ImageFont.truetype(font_path, 200)
    except:
        adaptive_font = ImageFont.load_default()
    
    # Calcular posição para ícone adaptativo
    bbox = adaptive_draw.textbbox((0, 0), config['letter'], font=adaptive_font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (432 - text_width) // 2
    y = (432 - text_height) // 2 - bbox[1]
    
    # Desenhar com sombra para melhor contraste
    shadow_offset = 3
    adaptive_draw.text((x + shadow_offset, y + shadow_offset), config['letter'], 
                      fill=(0, 0, 0, 128), font=adaptive_font)  # Sombra
    adaptive_draw.text((x, y), config['letter'], 
                      fill=config['color'], font=adaptive_font)  # Letra colorida
    
    # Salvar ícone adaptativo
    adaptive_path = f"{icon_dir}/adaptive_icon.png"
    adaptive_img.save(adaptive_path)
    print(f"✅ Ícone adaptativo criado: {adaptive_path}")
    
    return True

def main():
    if len(sys.argv) != 2:
        print("Uso: python3 scripts/create_example_icons.py [guara|vale_das_minas]")
        sys.exit(1)
    
    client = sys.argv[1]
    
    print(f"🎨 Criando ícones de exemplo para: {client}")
    print("📝 Nota: Estes são ícones de demonstração!")
    print("    Para produção, use ícones profissionais.")
    print()
    
    if create_icon_with_text(client, None, None):
        print()
        print("🚀 Próximos passos:")
        print(f"   1. Execute: ./scripts/generate_icons.sh {client}")
        print(f"   2. Execute: ./scripts/prepare_build.sh {client}")
        print()
        print("💡 Para ícones profissionais:")
        print("   - Substitua os arquivos em assets/icons/")
        print("   - Use resolução mínima de 1024x1024")
        print("   - Mantenha design simples e reconhecível")
    else:
        print("❌ Erro ao criar ícones de exemplo")
        sys.exit(1)

if __name__ == "__main__":
    main()