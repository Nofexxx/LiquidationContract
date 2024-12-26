FROM --platform=linux/amd64 ghcr.io/foundry-rs/foundry

# Install git, python, npm and required packages
RUN apk add --no-cache git python3 py3-pip nodejs npm

# Create mutations directory
WORKDIR /mutations

# Clone vertigo-rs inside mutations
RUN git clone https://github.com/RareSkills/vertigo-rs.git /mutations/vertigo_rs

# Install vertigo-rs
WORKDIR /mutations/vertigo_rs
RUN python3 setup.py develop

# Back to mutations
WORKDIR /mutations

# Copy current directory (smart contracts) into container
COPY . /mutations/
RUN rm -rf /mutations/mutations_results

# Install dependencies and build
RUN npm install 
RUN forge install
RUN forge compile

# Create tmp directory with proper permissions
WORKDIR /mutations
ENTRYPOINT ["sh", "-c", "python3 /mutations/vertigo_rs/vertigo.py run --output output/results_$(date +%Y%m%d_%H%M%S).txt"]
