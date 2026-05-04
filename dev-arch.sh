
#!/bin/bash
PROJECT_NAME=$1
shift

if [ "$PROJECT_NAME" = "--init-config" ]; then
        if [ -f "$HOME/.devarchrc" ]; then
                echo "Config already exists at ~/.devarchrc — not overwriting."
                exit 0
        fi
        cat > "$HOME/.devarchrc" << 'EOF'
# dev-arch configuration file
# Uncomment and change any values you want

# default_type=python
# default_type=web
# default_type=react

# default_git=false
# default_git=true

# default_tailwind=false
# default_tailwind=true
EOF
        echo "Config created at ~/.devarchrc"
        echo "Open it with: nano ~/.devarchrc"
        exit 0
fi

GIT=false
TYPE=""
TAILWIND=false

create_python_project(){
	mkdir src tests
	touch src/main.py requirements.txt README.md
}

create_web_project(){
	touch index.html style.css script.js README.md
}

create_react_project(){
	if ! command -v node &>/dev/null; then
		echo "Error: Node.js is not installed. Get it from https://nodejs.org"
		exit 1
	fi

	if ! command -v npm &>/dev/null; then
		echo "Error: npm is not installed. It usually comes with Node.js."
		exit 1
	fi
	echo "Scaffolding React + Vite project..."
	npx --yes create-vite temp_vite_scaffold -- --template react
	if [ $? -ne 0 ]; then
		echo "Error: Vite scaffolding failed."
		exit 1
	fi

	cp -r temp_vite_scaffold/. .
	rm -rf temp_vite_scaffold
	echo "Installing dependencies..."
	npm install
}

create_gitignore(){
	case $TYPE in
	python)
		echo "__pycache__/" > .gitignore
		echo "*.pyc" >> .gitignore
		echo ".env" >> .gitignore
		;;
	web)
		echo "node_modules/" > .gitignore
		echo "dist/" >> .gitignore
		echo ".env" >> .gitignore
		;;
	react)
		echo "node_modules/" > .gitignore
		echo "dist/" >> .gitignore
		echo ".env" >> .gitignore
		echo ".env.local" >> .gitignore
		;;
	*)
		touch .gitignore
		;;
	esac
}

setup_tailwind(){
	echo "Installing Tailwind CSS..."
	npm install tailwindcss @tailwindcss/vite
	sed -i "1s|^|import tailwindcss from '@tailwindcss/vite'\n|" vite.config.js
	sed -i "s|react()|react(),\n tailwindcss(),|" vite.config.js
	echo "@import 'tailwindcss';" > src/index.css
	echo "Tailwind CSS configured."
}

load_config(){
	DEFAULT_TYPE=""
	DEFAULT_GIT=false
	DEFAULT_TAILWIND=false

	local config_file="$HOME/.devarchrc"
	if [ ! -f "$config_file" ]; then 
		return
	fi

	while IFS='=' read -r key value; do
	# skip comments and blank lines 
	[[ "$key" =~ ^# ]] && continue
	[[ -z "$key"   ]] && continue

	   	case "$key" in
			default_type) DEFAULT_TYPE="$value" ;;
			default_git)  DEFAULT_GIT="$value"  ;;
			default_tailwind) DEFAULT_TAILWIND="$value" ;;
		esac
	done <"$config_file"
}

load_config
GIT=$DEFAULT_GIT
TYPE=$DEFAULT_TYPE
TAILWIND=$DEFAULT_TAILWIND
while [[ $# -gt 0 ]]; do
        case $1 in
        -t)
                TYPE=$2
                shift 2
                ;;
	-g)
		GIT=true
		shift
		;;
	-tw)
		TAILWIND=true
		shift
		;;
        *)
		echo "Error: Unknown option $1"
                exit 1
                ;;
        esac
done

#checking for duplicate or empty project name

if [ -z "$PROJECT_NAME" ]; then
	echo "Error: Please provide a project name."
	exit 1
fi

if [ -z "$TYPE" ]; then
	echo "Error: Please provide a project type using -t"
	exit 1
fi

if [ -d "$PROJECT_NAME" ]; then
        echo "Error: Directory already exists."
        exit 1
fi

echo "Creating Project: $PROJECT_NAME"
echo "Project Type: $TYPE"


if ! mkdir "$PROJECT_NAME"; then
        echo "Error: Failed to create the directory."
        exit 1
fi
cd "$PROJECT_NAME" || exit

case $TYPE in
python)
        create_python_project
        ;;
web)
        create_web_project
        ;;
react)
	create_react_project
	;;
*)
        echo "Error: Unknown project type"
        exit 1
esac

if [ "$TAILWIND" = true ] && [ "$TYPE" != "react" ]; then
	echo "Error: -tw flag is only supported with -t react for now."
	rmdir "../$PROJECT_NAME"
	exit 1
fi

if [ "$TAILWIND" = true ]; then
	setup_tailwind
fi

if [ "$GIT" = true ]; then
        echo "Initializing Git repository..."
        git init
        create_gitignore
fi

echo "Project created successfull"

if [ "$TYPE" = "react" ]; then
	echo ""
	echo "Next steps:"
	echo "cd $PROJECT_NAME"
	echo "npm run dev"
fi
