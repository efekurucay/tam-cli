import Foundation

/// Pre-built alias packs for common developer workflows.
struct AliasPack: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let description: String
    let emoji: String
    let tags: [String]
    let aliases: [AliasItem]

    // Hashable by id
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: AliasPack, rhs: AliasPack) -> Bool { lhs.id == rhs.id }

    static let allPacks: [AliasPack] = [gitPack, dockerPack, kubernetesPack, nodePack, systemPack]

    // MARK: - Git

    static let gitPack = AliasPack(
        name: "Git",
        description: "Everyday Git shortcuts — status, commit, push, branch and more.",
        emoji: "🌿",
        tags: ["git"],
        aliases: [
            AliasItem(name: "gs",    command: "git status",              comment: "Git status",           tags: ["git"]),
            AliasItem(name: "ga",    command: "git add",                  comment: "Git add",              tags: ["git"]),
            AliasItem(name: "gaa",   command: "git add --all",            comment: "Git add all",          tags: ["git"]),
            AliasItem(name: "gc",    command: "git commit -m",            comment: "Git commit",           tags: ["git"]),
            AliasItem(name: "gca",   command: "git commit --amend",       comment: "Git commit amend",     tags: ["git"]),
            AliasItem(name: "gp",    command: "git push",                 comment: "Git push",             tags: ["git"]),
            AliasItem(name: "gpl",   command: "git pull",                 comment: "Git pull",             tags: ["git"]),
            AliasItem(name: "gf",    command: "git fetch",                comment: "Git fetch",            tags: ["git"]),
            AliasItem(name: "gl",    command: "git log --oneline -20",    comment: "Git log (compact)",    tags: ["git"]),
            AliasItem(name: "gd",    command: "git diff",                 comment: "Git diff",             tags: ["git"]),
            AliasItem(name: "gds",   command: "git diff --staged",        comment: "Git diff staged",      tags: ["git"]),
            AliasItem(name: "gb",    command: "git branch",               comment: "Git branches",         tags: ["git"]),
            AliasItem(name: "gco",   command: "git checkout",             comment: "Git checkout",         tags: ["git"]),
            AliasItem(name: "gcob",  command: "git checkout -b",          comment: "New branch",           tags: ["git"]),
            AliasItem(name: "gst",   command: "git stash",                comment: "Git stash",            tags: ["git"]),
            AliasItem(name: "gstp",  command: "git stash pop",            comment: "Git stash pop",        tags: ["git"]),
            AliasItem(name: "grh",   command: "git reset --hard HEAD",    comment: "Git reset hard",       tags: ["git"]),
        ]
    )

    // MARK: - Docker

    static let dockerPack = AliasPack(
        name: "Docker",
        description: "Docker and Docker Compose shortcuts for container management.",
        emoji: "🐳",
        tags: ["docker"],
        aliases: [
            AliasItem(name: "dps",     command: "docker ps",                comment: "List running containers", tags: ["docker"]),
            AliasItem(name: "dpsa",    command: "docker ps -a",             comment: "List all containers",     tags: ["docker"]),
            AliasItem(name: "di",      command: "docker images",            comment: "List images",              tags: ["docker"]),
            AliasItem(name: "drm",     command: "docker rm",                comment: "Remove container",         tags: ["docker"]),
            AliasItem(name: "drmi",    command: "docker rmi",               comment: "Remove image",             tags: ["docker"]),
            AliasItem(name: "dex",     command: "docker exec -it",          comment: "Exec into container",      tags: ["docker"]),
            AliasItem(name: "dlogs",   command: "docker logs -f",           comment: "Follow container logs",    tags: ["docker"]),
            AliasItem(name: "dstop",   command: "docker stop",              comment: "Stop container",           tags: ["docker"]),
            AliasItem(name: "dstart",  command: "docker start",             comment: "Start container",          tags: ["docker"]),
            AliasItem(name: "dclean",  command: "docker system prune -f",   comment: "Clean unused resources",   tags: ["docker"]),
            AliasItem(name: "dcup",    command: "docker compose up -d",     comment: "Compose up (detached)",    tags: ["docker"]),
            AliasItem(name: "dcdown",  command: "docker compose down",      comment: "Compose down",             tags: ["docker"]),
            AliasItem(name: "dclogs",  command: "docker compose logs -f",   comment: "Compose logs",             tags: ["docker"]),
            AliasItem(name: "dcbuild", command: "docker compose build",     comment: "Compose build",            tags: ["docker"]),
        ]
    )

    // MARK: - Kubernetes

    static let kubernetesPack = AliasPack(
        name: "Kubernetes",
        description: "kubectl shortcuts for everyday k8s operations.",
        emoji: "⚙️",
        tags: ["k8s"],
        aliases: [
            AliasItem(name: "k",      command: "kubectl",                                      comment: "kubectl shorthand",     tags: ["k8s"]),
            AliasItem(name: "kgp",    command: "kubectl get pods",                             comment: "Get pods",              tags: ["k8s"]),
            AliasItem(name: "kgpa",   command: "kubectl get pods --all-namespaces",            comment: "Get all pods",          tags: ["k8s"]),
            AliasItem(name: "kgs",    command: "kubectl get services",                         comment: "Get services",          tags: ["k8s"]),
            AliasItem(name: "kgd",    command: "kubectl get deployments",                      comment: "Get deployments",       tags: ["k8s"]),
            AliasItem(name: "kdesc",  command: "kubectl describe",                             comment: "Describe resource",     tags: ["k8s"]),
            AliasItem(name: "klog",   command: "kubectl logs -f",                              comment: "Follow pod logs",       tags: ["k8s"]),
            AliasItem(name: "kex",    command: "kubectl exec -it",                             comment: "Exec into pod",         tags: ["k8s"]),
            AliasItem(name: "kns",    command: "kubectl config set-context --current --namespace", comment: "Set namespace",    tags: ["k8s"]),
            AliasItem(name: "kctx",   command: "kubectl config use-context",                  comment: "Switch context",        tags: ["k8s"]),
            AliasItem(name: "kapply", command: "kubectl apply -f",                             comment: "Apply manifest",        tags: ["k8s"]),
            AliasItem(name: "kdel",   command: "kubectl delete",                               comment: "Delete resource",       tags: ["k8s"]),
        ]
    )

    // MARK: - Node

    static let nodePack = AliasPack(
        name: "Node / npm",
        description: "Node.js, npm, and yarn shortcuts.",
        emoji: "📦",
        tags: ["node"],
        aliases: [
            AliasItem(name: "ni",   command: "npm install",           comment: "npm install",          tags: ["node"]),
            AliasItem(name: "nid",  command: "npm install --save-dev", comment: "npm install dev dep",  tags: ["node"]),
            AliasItem(name: "nr",   command: "npm run",               comment: "npm run",              tags: ["node"]),
            AliasItem(name: "nrd",  command: "npm run dev",           comment: "npm run dev",          tags: ["node"]),
            AliasItem(name: "nrb",  command: "npm run build",         comment: "npm run build",        tags: ["node"]),
            AliasItem(name: "nrt",  command: "npm run test",          comment: "npm run test",         tags: ["node"]),
            AliasItem(name: "nrs",  command: "npm run start",         comment: "npm start",            tags: ["node"]),
            AliasItem(name: "yi",   command: "yarn install",          comment: "yarn install",         tags: ["node"]),
            AliasItem(name: "ya",   command: "yarn add",              comment: "yarn add",             tags: ["node"]),
            AliasItem(name: "yad",  command: "yarn add --dev",        comment: "yarn add dev dep",     tags: ["node"]),
            AliasItem(name: "yd",   command: "yarn dev",              comment: "yarn dev",             tags: ["node"]),
            AliasItem(name: "yb",   command: "yarn build",            comment: "yarn build",           tags: ["node"]),
        ]
    )

    // MARK: - System

    static let systemPack = AliasPack(
        name: "System",
        description: "macOS system and shell utilities.",
        emoji: "🖥️",
        tags: ["system"],
        aliases: [
            AliasItem(name: "ll",     command: "ls -la",                                                             comment: "Long listing",              tags: ["system"]),
            AliasItem(name: "la",     command: "ls -A",                                                              comment: "List all (no . and ..)",    tags: ["system"]),
            AliasItem(name: "l",      command: "ls -CF",                                                             comment: "Compact listing",           tags: ["system"]),
            AliasItem(name: "lh",     command: "ls -lah",                                                            comment: "Human-readable sizes",      tags: ["system"]),
            AliasItem(name: "cls",    command: "clear",                                                              comment: "Clear terminal",            tags: ["system"]),
            AliasItem(name: "reload", command: "source ~/.zshrc",                                                    comment: "Reload zsh config",         tags: ["system"]),
            AliasItem(name: "zshrc",  command: "open ~/.zshrc",                                                      comment: "Open zshrc",                tags: ["system"]),
            AliasItem(name: "ip",     command: "ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}'",    comment: "Local IP address",          tags: ["system"]),
            AliasItem(name: "pubip",  command: "curl -s ifconfig.me",                                               comment: "Public IP address",         tags: ["system"]),
            AliasItem(name: "ports",  command: "lsof -i -P -n | grep LISTEN",                                       comment: "List open ports",           tags: ["system"]),
            AliasItem(name: "rmds",   command: "find . -name '.DS_Store' -delete",                                  comment: "Remove .DS_Store files",    tags: ["system"]),
        ]
    )
}
