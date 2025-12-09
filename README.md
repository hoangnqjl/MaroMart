MaroMart
MaroMart is an e-commerce / marketplace application (frontend + backend + admin) that allows users to easily buy and sell products online.

🎯 Goals & Features
Users can browse product categories, view product details, add items to the cart, and place orders.
Admin dashboard for managing products, orders, and users.
Role-based access control (client/admin).
Separated frontend and backend architecture for easier maintenance and scalability.

📁 Project Structure
/Admin      # Admin dashboard — product, user, category, statistic management
/Client     # Frontend for users — product view, buy, chat, profile
/Server     # Backend — APIs, business logic, database management, authentication

🚀 Installation & Running
Requirements
Node.js (specify version used)
Database (MySQL / PostgreSQL / MongoDB, depending on backend)

Environment variables:
PORT
MONGODB_URI
STRIPE_API_SECRET
JWT_SECRET
JWT_EXPIRES_TIME
cookie_EXPIRES_TIME
SMTP_HOST
SMTP_PORT
SMTP_EMAIL
SMTP_PASSWORD
SMTP_FROM_EMAIL
SMTP_FROM_NAME
CLOUDINARY_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
GEMINI_API_KEY


Clone the repository:
git clone https://github.com/hoangnqjl/MaroMart.git

Backend
cd MaroMart/Server
npm install
npm run dev        # start backend server

Frontend (Flutter)
cd ../Client
flutter pub get
flutter run         # start frontend app

Admin Dashboard
cd ../Admin
npm install
npm start

🧑‍💻 Usage
Open the Flutter frontend application on a device or emulator.
Register / log in (if authentication is implemented).
Browse and search products, add items to the cart, and place orders.
Admin: log in to the dashboard to manage products, view orders, and manage users.

📦 Technologies Used
Frontend: React / Vue / TypeScript
Backend: Node.js (ExpressJS + TypeScript) + Database (MongoDB)
Mobile / Hybrid: Dart / Flutter
Architecture: Client, Server, Admin
