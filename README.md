MaroMart

MaroMart is an e-commerce / marketplace application (frontend + backend + admin) that allows users to easily buy and sell products online.

🎯 Goals & Features

Users can browse product categories, view product details, add items to the cart, and place orders.

Admin dashboard for managing products, orders, and users.

Role-based access control (client/admin).

Separated frontend and backend architecture for easier maintenance and scalability.

📁 Project Structure
/Admin      # Admin dashboard — product, order, and user management
/Client     # Frontend for users — product browsing, cart, checkout, profile
/Server     # Backend — APIs, business logic, database management, authentication
.idea       # IDE configuration (can be ignored)

🚀 Installation & Running
Requirements

Node.js (specify version used)

Database (MySQL / PostgreSQL / MongoDB, depending on backend)

Environment variables (e.g., DB_URL, JWT_SECRET, etc.)

Quick Start
# Clone the repository
git clone https://github.com/hoangnqjl/MaroMart.git

# Backend
cd MaroMart/Server
npm install
npm run dev        # start backend server

# Frontend
cd ../Client
npm install
npm start          # start frontend app

# Admin Dashboard (if applicable)
cd ../Admin
npm install
npm start


💡 If Docker or docker-compose is used, provide instructions accordingly.

🧑‍💻 Usage

Open the frontend URL in a browser.

Register / login (if authentication is implemented).

Browse and search products, add to cart, place orders.

Admin: log in to the dashboard to manage products, view orders, and manage users.

📦 Technologies Used

Frontend: React / Next.js / Vue / Angular + TypeScript + HTML/CSS (depending on the repo)

Backend: Node.js (Express / NestJS / …) + Database (MySQL / PostgreSQL / MongoDB / …)

Mobile / Hybrid (if any): Dart / Flutter

Architecture: Client, Server, Admin — clean separation for maintainability and scalability

✅ Roadmap / Future Improvements

Add product search and pagination

Integrate payment gateway

Advanced order management: status tracking, email notifications

UI/UX improvements and responsive design

Add tests for backend and frontend, CI/CD pipeline

📚 Contributing

Contributions are welcome! To contribute:

Fork the repository

Create a new branch: feature/YourFeature or bugfix/YourFix

Commit and push changes with clear descriptions

Open a Pull Request for review

👤 Author

Original repository: @hoangnqjl

GitHub profile: https://github.com/hoangnqjl
