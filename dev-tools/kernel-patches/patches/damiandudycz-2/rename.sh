#!/bin/bash

# Iterujemy przez wszystkie pliki w bieżącym katalogu
for file in *; do
    # Pomijamy katalogi
    if [ -f "$file" ]; then
        # Zmieniamy nazwę pliku na małe litery
        lowercased=$(echo "$file" | tr '[:upper:]' '[:lower:]')
        
        # Sprawdzamy, czy nowa nazwa jest inna od starej
        if [ "$file" != "$lowercased" ]; then
            mv "$file" "$lowercased"
        fi
    fi
done

