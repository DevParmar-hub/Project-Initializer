
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


if [ "$PROJECT_NAME" = "--help" ]; then
	echo "Usage: dev-arch <project_name> -t <type> [options]"
	echo ""
	echo "Project types:"
	echo " -t python	Create a Python project"
	echo " -t web		Create a web project"
	echo " -t react 	Create a React + Vite project"
	echo " -t node      Create a Node + Express + MongoDB backend"
	echo " -t fullstack Create a React frontend + Node backend"
	echo ""
	echo " Options:"
	echo " --full 		Generate working boilerplate code for NODE projects "
	echo " -g 		Initialize a Git repository"
	echo " -G		Create a GitHub repository and push"
	echo " --private	Make a GitHub repository private"
	echo " -tw 		Add Tailwind CSS (react only)"
	echo ""
	echo " Config:"
	echo " --init-config 	Generate a starter ~/.devarchrc config file"
	echo " --help 		Show this help message"
	exit 0
fi

GIT=false
TYPE=""
TAILWIND=false
GITHUB=false
VISIBILITY="public"
FULL=false

create_python_project(){
	mkdir src tests
	touch src/main.py requirements.txt README.md
}

create_web_project(){
	touch index.html style.css script.js README.md
}

create_react_project(){
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

	if ! command -v node &>/dev/null; then
		echo "Error: Node.js is not installed. Get it from https://nodejs.org"
		exit 1
	fi

	if ! command -v npm &>/dev/null; then
		echo "Error: npm is not installed. It usually comes with Node.js."
		exit 1
	fi
	echo "Scaffolding React + Vite project..."
	npx --yes create-vite temp_vite_scaffold --template react
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

setup_github(){
	if ! command -v gh &>/dev/null; then
		echo "Error: Github CLI is not installed. Get it from https://cli.github.com"
		exit 1
	fi

	if ! gh auth status &>/dev/null; then 
		echo "Error: Not logged in to Github CLI."
		echo "Run: gh auth login"
		exit 1
	fi

echo "Creating GitHub repository..."
gh repo create "$PROJECT_NAME" \
	--source=. \
	--remote=origin \
	--push \
	"--$VISIBILITY"

	if [ $? -ne 0 ]; then
		echo "Error: GitHub rep creation failed."
		exit 1
	fi

echo "Repository created: https://github.com/$(gh api user -q .login)/$PROJECT_NAME"


}

create_node_project(){
	mkdir config routes controllers models middleware services utils validators uploads
	touch README.md .env

	cat > package.json << 'EOF'
{
	  "name": "node-project",
  	"version": "1.0.0",
  	"type": "module",
  	"scripts": {
    	"start": "node server.js",
    	"dev": "nodemon server.js"
},
  	"dependencies": {
    	"express": "^4.18.2",
    	"mongoose": "^8.0.0",
    	"dotenv": "^16.3.1",
    	"cors": "^2.8.5"
},
  	"devDependencies": {
    	"nodemon": "^3.0.2"
}
}
EOF

	printf "node_modules/\n.env\ndist/\nuploads/*\n!uploads/.gitkeep\n" > .gitignore
	touch uploads/.gitkeep

	printf "PORT=3000\nMONGODB_URI=your_mongodb_atlas_connection_string\nNODE_ENV=development\n" > .env

	if [ "$FULL" = true ]; then
	cat > server.js << 'EOF'
	import app from './app.js'
	import dotenv from 'dotenv'
	dotenv.config()

	const PORT = process.env.PORT || 3000
	app.listen(PORT, () => {
		console.log(`Server is running on port ${PORT}`)
	})
EOF

	cat > app.js << 'EOF'
	import express from 'express'
	import cors from 'cors'
	import dotenv from 'dotenv'
	import { connectDB } from './config/db.js'
	import routes from './routes/index.js'

	dotenv.config()
	connectDB()

	const app = express()
	app.use(cors())
	app.use(express.json())
	app.use('/api', routes)

	export default app
EOF

	cat > config/db.js << 'EOF'
	import mongoose from 'mongoose'
	export const connectDB = async () => {
  	try {
    		await mongoose.connect(process.env.MONGODB_URI)
    		console.log('MongoDB connected')
  	}
	catch (err) {
    	console.error('MongoDB connection failed:', err.message)
    	process.exit(1)
  }
}
EOF

	cat > routes/index.js <<'EOF'
	import { Router } from 'express'
	const router = Router()

	router.get('/health', (req, res) => {
  		res.json({ status: 'ok' })
	})

	export default router
EOF

	cat > controllers/index.js << 'EOF'
	export const healthCheck = (req, res) => {
		res.json({ status: 'ok' })
}
EOF


	cat > models/index.js << 'EOF'
// Export your mongoose models here
// For example:
// export { default as User } from '.User.js'
EOF

	cat > middleware/index.js << 'EOF'
	export const errorHandler = (err, req, res, next) => {
	console.error(err.stack)
	res.status(500).json({ message: err.message })
}
EOF

	cat > services/index.js << 'EOF'
//Business logic goes here
EOF

	cat > utils/index.js << 'EOF'
//Utility/helper functions go here
EOF

	cat > validators/index.js << 'EOF'
//Request validators go here
EOF

	else
		touch server.js app.js config/db.js routes/index.js controllers/index.js
		touch models/index.js middleware/index.js services/index.js utils/index.js validators/index.js
	fi
}

create_fullstack_project(){
	mkdir frontend backend

	cd frontend
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
	npx --yes create-vite temp_vite_scaffold --template react
	cp -r temp_vite_scaffold/. .
	rm -rf temp_vite_scaffold
	npm install
	cd ..

	cd backend
	TYPE="node" create_node_project
	cd ..
}

	load_config(){
	DEFAULT_TYPE=""
	DEFAULT_GIT=false
	DEFAULT_TAILWIND=false
	DEFAULT_GITHUB=false
	DEFAULT_VISIBILITY="public"
	DEFAULT_FULL=false

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
			default_github) DEFAULT_GITHUB="$value" ;;
			default_visibility) DEFAULT_VISIBILITY="$value" ;;
			default_full) DEFAULT_FULL="$value" ;;
		esac
	done <"$config_file"
}

load_config
GIT=$DEFAULT_GIT
TYPE=$DEFAULT_TYPE
TAILWIND=$DEFAULT_TAILWIND
GITHUB=$DEFAULT_GITHUB
VISIBILITY=$DEFAULT_VISIBILITY
FULL=$DEFAULT_FULL

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
	--full)
		FULL=true
		shift
		;;
	-G)
		GITHUB=true
		GIT=true
		shift
		;;
	--private)
		VISIBILITY="private"
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
node)
	create_node_project
	;;
fullstack)
	create_fullstack_project
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
	git add .
	git commit -m "Initial commit"
fi

if [ "$GITHUB" = true ]; then
	setup_github
fi

echo "Project created successfull"

if [ "$TYPE" = "react" ]; then
	echo ""
	echo "Next steps:"
	echo "cd $PROJECT_NAME"
	echo "npm run dev"
fi
