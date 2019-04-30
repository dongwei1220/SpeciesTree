library(ggtree)

tree1 <- read.newick("./RAxML_cds.concatenate_tree.nwk",node.label = "support")
p1 <- ggtree(tree1,color="black",linetype=1,size=1.5,ladderize = T,branch.length = "none") + xlim(0,14) +
    geom_tiplab(hjust = -0.05,size=10,fontface="italic") + 
    geom_text2(aes(subset=!isTip,label=support,hjust=-0.5),size=6) + 
    geom_point2(aes(subset=!isTip,fill=support),shape=21,size=4)
pdf("RAxML_cds.concatenate_tree.pdf",width=16,height=16)
print(p1)
dev.off()
png("RAxML_cds.concatenate_tree.png",width=1200,height=1200)
print(p1)
dev.off()

tree2 <- read.newick("./RAxML_pep.concatenate_tree.nwk",node.label = "support")
p2 <- ggtree(tree2,color="black",linetype=1,size=1.5,ladderize = T,branch.length = "none") + xlim(0,14) +
	geom_tiplab(hjust = -0.05,size=10,fontface="italic") + 
	geom_text2(aes(subset=!isTip,label=support,hjust=-0.5),size=6) +
	geom_point2(aes(subset=!isTip,fill=support),shape=21,size=4)
pdf("RAxML_pep.concatenate_tree.pdf",width=16,height=16)
print(p2)
dev.off()
png("RAxML_pep.concatenate_tree.png",width=1200,height=1200)
print(p2)
dev.off()


tree3 <- read.newick("./Astral_cds.coalescent_tree.nwk",node.label = "support")
p3 <- ggtree(tree3,color="black",linetype=1,size=1.5,ladderize = T,branch.length = "none") + xlim(0,14) +
	geom_tiplab(hjust = -0.05,size=10,fontface="italic") +
	geom_text2(aes(subset=!isTip,label=support,hjust=-0.5),size=6) +
	geom_point2(aes(subset=!isTip,fill=support),shape=21,size=4)
pdf("Astral_cds.coalescent_tree.pdf",width=16,height=16)
print(p3)
dev.off()
png("Astral_cds.coalescent_tree.png",width=1200,height=1200)
print(p3)
dev.off()

tree4 <- read.newick("./Astral_pep.coalescent_tree.nwk",node.label = "support")
p4 <- ggtree(tree3,color="black",linetype=1,size=1.5,ladderize = T,branch.length = "none") + xlim(0,14) +
	geom_tiplab(hjust = -0.05,size=10,fontface="italic") +
	geom_text2(aes(subset=!isTip,label=support,hjust=-0.5),size=6) +
	geom_point2(aes(subset=!isTip,fill=support),shape=21,size=4)
pdf("Astral_pep.coalescent_tree.pdf",width=16,height=16)
print(p4)
dev.off()
png("Astral_pep.coalescent_tree.png",width=1200,height=1200)
print(p4)
dev.off()
