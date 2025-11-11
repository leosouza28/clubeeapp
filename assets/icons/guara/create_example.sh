# Script para criar ícones de exemplo para Guará
# Execute este comando no terminal para criar um ícone de exemplo:

# Usando ImageMagick (se instalado):
# convert -size 1024x1024 xc:'#1976D2' -fill white -gravity center -pointsize 200 -annotate +0+0 'G' assets/icons/guara/icon.png

# Usando Python PIL (se instalado):
# python3 -c "
# from PIL import Image, ImageDraw, ImageFont
# import os
# os.makedirs('assets/icons/guara', exist_ok=True)
# img = Image.new('RGBA', (1024, 1024), (25, 118, 210, 255))
# draw = ImageDraw.Draw(img)
# try:
#     font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 400)
# except:
#     font = ImageFont.load_default()
# bbox = draw.textbbox((0, 0), 'G', font=font)
# text_width = bbox[2] - bbox[0]
# text_height = bbox[3] - bbox[1]
# x = (1024 - text_width) // 2
# y = (1024 - text_height) // 2
# draw.text((x, y), 'G', fill='white', font=font)
# img.save('assets/icons/guara/icon.png')
# print('Ícone Guará criado!')
# "

echo "📝 Para criar ícones de exemplo, execute um dos comandos acima"
echo "   Ou coloque seus próprios ícones nos arquivos:"
echo "   - assets/icons/guara/icon.png (1024x1024)"
echo "   - assets/icons/guara/adaptive_icon.png (432x432)"