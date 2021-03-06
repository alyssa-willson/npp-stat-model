library(reshape2)
library(ggplot2)

source('r/utils/plot_funs.r')
source('config')

figures_dir = 'NOCOVAR'
if (!file.exists(figures_dir)){
  dir.create(paste0("figures/", figures_dir))
}


fname_data = paste0('tree_data_20_', dvers)
load(file=paste0('data/dump/', fname_data, '.rdata'))
fname_data = paste0('tree_data_20_no_census_', dvers)
load(file=paste0('data/dump/', fname_data, '.rdata'))

# fnames = c('ring_model_t_date_sapl_size_pdbh', 'ring_model_t_date_sapl_size_pdbh_nc')
# fnames = c('ring_model_t_date_sapl_size_pdbh', 'ring_model_t_size_pdbh_nc')
# fnames = c('ring_model_t_date_sapl_size_pdbh', 'ring_model_t_pdbh_nc')
fnames = c('ring_model_t_date_sapl_size_pdbh_NOCOVAR', 'ring_model_t_pdbh_nc_NOCOVAR_sigd')
models = c('Model RW + Census', 'Model RW')

post= list()

for (i in 1:length(fnames)) {
  fname_model = fnames[i]
  load(file   = paste0('output/', fname_model, '_', mvers, '.Rdata'))
  post[[i]]   = out[1:1000,]#out[1:2000,]
}  

burn  = 800#400
niter = dim(out)[1]


########################################################################################################################################
library(RColorBrewer)
darkcols <- brewer.pal(4, "Set1")

nc=FALSE
x2idx_p = match(x2tree_p, unique(x2tree_p))

trees = sort(unique(x2tree))
trees_p = sort(unique(x2tree_p))

pdf(paste0('figures/', figures_dir, '/growth_results_both_HF_', mvers, '.pdf'), width=12, height=10)
for (i in 1:N_trees){
  
  print(paste0('Tree ', i))
  
  tree = trees[i]
  tree_p = trees_p[trees_p==tree]
  
  tree_idx = which(x2tree == tree)
  tree_idx_p =  which(x2tree_p == tree_p)
  
  # estimated increment
  # X_mu = lapply(post, function(x) colMeans(x[,get_cols(x,'X')[tree_idx]]))
  # X_mu_p = lapply(post, function(x) colMeans(x[,get_cols(x[[2]],'X')[tree_idx_p]]))[[1]]
  # estimated increment
  # X_mu = lapply(post, function(x) colMeans(x[,get_cols(post[[1]],'X')[tree_idx]]))[[1]]
  X_qs = apply(post[[1]][,get_cols(post[[1]],'X')[tree_idx]], 2, function(x) quantile(x, probs=c(0.025,0.5, 0.975)))
  X_qs_p = apply(post[[2]][,get_cols(post[[2]],'X')[tree_idx_p]], 2, function(x) quantile(x, probs=c(0.025,0.5, 0.975)))
  
  
  tree_years = x2year[tree_idx]
  tree_years_p = x2year_p[tree_idx_p]
  
  # raw data
  dat_idx   = which(m2tree == tree)
  core_nums = unique(m2orient[dat_idx])
  rws = exp(logXobs[dat_idx])
  
  if (length(rws)>0){
    ymin = min(c(rws,X_qs[1,]))
    ymax = max(c(rws,X_qs[3,]))
  } else {
    ymin = min(X_qs[1,])
    ymax = max(X_qs[3,])
  }
  
  
  tree_dat = data.frame(value=numeric(0), year=numeric(0), var=character(0), type=character(0), subtype=character(0))
  tree_dat = rbind(tree_dat, data.frame(value=X_qs[2,], year=years[tree_years], var=rep('RW'), type=rep('model'), subtype=rep('Both')))
  
  ribbon_dat = data.frame(L=numeric(0), U=numeric(0), year=numeric(0), var=character(0), subtype=character(0))
  ribbon_dat = rbind(ribbon_dat, data.frame(L=X_qs[1,], U=X_qs[3,], year=years[tree_years], var=rep('RW'), subtype=rep('Both')))
  
  if (length(tree_idx_p)>0){
    tree_dat = rbind(tree_dat, data.frame(value=X_qs_p[2,], year=years[tree_years_p], var=rep('RW'), type=rep('model'), subtype=rep('RW')))
    ribbon_dat = rbind(ribbon_dat, data.frame(L=X_qs_p[1,], U=X_qs_p[3,], year=years[tree_years_p], var=rep('RW'), subtype=rep('RW')))
  }
  
  if (length(core_nums) > 1) {
    idx_a = which(m2tree_a == tree)
    dat   = exp(logXobs_a[idx_a])
    yrs   = m2t_a[idx_a] 
    
    tree_dat = rbind(tree_dat, data.frame(value=dat, year=yrs, var=rep('RW'), type=rep('data'), subtype=rep('raw avg')))
    
  }
  
  for (core in core_nums){
    idx = which((m2tree == tree) & (m2orient == core))
    yrs = m2t[idx] 
    # lines(yrs, exp(logXobs[idx]), col='black', lty=2)
    
    tree_dat = rbind(tree_dat, data.frame(value=exp(logXobs[idx]), year=yrs, var=rep('RW'), type=rep('data'), subtype=rep(core)))
    
  }
  
  # ggplot(tree_dat) + geom_line(aes(x=year, y=value, colour=subtype))
  
  # now plot D!
  
  #   D_mu = colMeans(post[,which(col_names=="D")[tree_idx]])
  #   D_quants = apply(post[,which(col_names=="D")[tree_idx]], 2, function(x) quantile(x, probs=c(0.025,0.5, 0.975)))
  
  D_qs = apply(post[[1]][,get_cols(post[[1]],'D')[tree_idx]], 2, function(x) quantile(x, probs=c(0.025,0.5, 0.975)))
  D_qs_p = apply(post[[2]][,get_cols(post[[2]],'D')[tree_idx_p]], 2, function(x) quantile(x, probs=c(0.025,0.5, 0.975)))
  
  tree_dat = rbind(tree_dat, data.frame(value=D_qs[2,], year=years[tree_years], var=rep('DBH'), type=rep('model'), subtype=rep('Both')))
  
  ribbon_dat = rbind(ribbon_dat, data.frame(L=D_qs[1,], U=D_qs[3,], year=years[tree_years], var=rep('DBH'), subtype=rep('Both')))
  
  if (length(tree_idx_p)>0){
    tree_dat = rbind(tree_dat, data.frame(value=D_qs_p[2,], year=years[tree_years_p], var=rep('DBH'), type=rep('model'), subtype=rep('RW')))
    ribbon_dat = rbind(ribbon_dat, data.frame(L=D_qs_p[1,], U=D_qs_p[3,], year=years[tree_years_p], var=rep('DBH'), subtype=rep('RW')))
  }
  
  D_dat = NA
  if (!nc){
    idx_dbh = which(dbh_tree_id == tree)
    yrs = dbh_year_id[idx_dbh]
    
    D_dat = exp(logDobs[idx_dbh])
  }
  
  ymax = max(c(D_dat,D_qs[2,]), na.rm=TRUE)
  
  tree_dat = rbind(tree_dat, data.frame(value=D_dat, year=years[yrs], var=rep('DBH'), type=rep('data'), subtype=rep('census')))
  
  
  if (any(pdbh_tree_id == tree)){
    
    idx_pdbh = which(pdbh_tree_id == tree)
    yrs = pdbh_year_id[idx_pdbh]
    
    PD_dat = exp(logPDobs[idx_pdbh])
    
    ymax = max(c(PD_dat,ymax))
    
    tree_dat = rbind(tree_dat, data.frame(value=PD_dat, year=years[yrs], var=rep('DBH'), type=rep('data'), subtype=rep('paleon')))
    
  } else {
    tree_dat = rbind(tree_dat, data.frame(value=NA, year=NA, var=rep('DBH'), type=rep('data'), subtype=rep('paleon')))
    
  }
  
  # points(years[yrs], D_dat, pch=19, col='black')  
  if(!nc){
    if (tree %in% sapling_tree_id) {
      idx_sap = which(sapling_tree_id == tree)
      years_sap = years[sapling_year_id[idx_sap]]
      # years_sap = sapling_year_id[idx_sap]
      
      # points(years_sap, max_size[idx_sap], col='red', pch=19)
      
      tree_dat = rbind(tree_dat, data.frame(value=max_size[idx_sap], year=years_sap, var=rep('DBH'), type=rep('data'), subtype=rep('sapling')))
    }
  } else {
    tree_dat = rbind(tree_dat, data.frame(value=NA, year=NA, var=rep('DBH'), type=rep('data'), subtype=rep('sapling')))
  }
  
  # cols = brewer.pal(9, 'Set1')
  #cols = c('red', 'blue', 'green', 'black')#, 'black')
  # cols = c('#084594', '#9ecae1')
  #8c2d04, #fdae6b
  # cols = c('#084594', '#8c2d04')
  # cols_fill = c('#4292c6', '#feedde')
  cols = c('#084594', '#8c2d04')
  # cols_fill = c('#4292c6', '#feedde')
  cols_fill = c('#4292c6', 'coral2')
  
  # levels(tree_dat$var) <- c("Increment (mm)", "DBH (cm)")
  
  # transform(iris, Species = c("S", "Ve", "Vi")[as.numeric(Species)])
  
  census_id = dbh[which(dbh$stat_id == tree), 'census_id']
  hf_id = dbh[which(dbh$stat_id == tree), 'id']
  
  p <- ggplot(tree_dat) + geom_ribbon(data=ribbon_dat, aes(x=year, ymin=L, ymax=U, fill=subtype), alpha=0.4) + 
    geom_line(data=subset(tree_dat, type %in% c('model')), aes(x=year, y=value, colour=subtype), size=1) + 
    geom_point(data=subset(tree_dat, (type %in% c('data')) & (var %in% c('RW')) & (subtype %in% c('raw avg'))), 
               aes(x=year, y=value, group=subtype), colour='brown', size=4, shape=20, alpha=0.5) +
    geom_line(data=subset(tree_dat, (type %in% c('data')) & (var %in% c('RW')) & (!(subtype %in% c('raw avg')))), 
              aes(x=year, y=value, group=subtype), alpha=0.7,  colour='black', linetype=2, size=0.8, show.legend=FALSE) +
    geom_point(data=subset(tree_dat, (type %in% c('data')) & (var %in% c('DBH'))) , 
               aes(x=year, y=value, shape=subtype), size=3) +
    scale_color_manual(values=cols, name='Data', labels=c('RW + Census', 'RW')) + 
    scale_fill_manual(values=cols_fill, name='Data', labels=c('RW + Census', 'RW')) + 
    scale_shape_manual(values=c(19, 8, 10), guide='none') +
    # guides(fill = FALSE,
    #    colour = guide_legend(override.aes = list(colour = c('red', 'blue', 'green')))) +
    theme_bw()+
    theme(axis.title.y=element_blank()) + 
    theme(axis.title=element_text(size=18), 
          axis.text=element_text(size=18), 
          legend.text=element_text(size=18), 
          legend.title=element_text(size=18),
          strip.text = element_text(size=18)) +
    scale_x_continuous(breaks=seq(min(years), max(years), by=5)) + 
    facet_grid(var~., scales="free_y") + 
    ggtitle(paste0('Stat id: ', i , '; Census id: ', census_id, '; PalEON id :', hf_id)) #+ 
  # annotate("text",  x=min(tree_dat$year), y = Inf, label = "Some text", vjust=1, hjust=-3)
  
  print(p)
}
dev.off()


# ggplot() +  geom_ribbon(data=ab_p_quants, aes(x=year, ymin=ab25, ymax=ab975, fill=model), alpha=0.4) +
#   geom_line(data=ab_p_quants, aes(x=year, y=ab50, colour=model), size=1) + 
#   geom_line(data=ab_m_sum, aes(x=year, y=ab, colour='Empirical RW', fill='Empirical RW'),size=1) + 
#   geom_point(data=ab_c_sum, aes(x=year, y=ab, colour='Empirical Census', fill='Empirical Census'), size=2) + 
#   # geom_line(data=ab_p_quants, aes(x=year, y=ab25, colour=model), linetype=2, size=0.5) + 
#   # geom_line(data=ab_p_quants, aes(x=year, y=ab975, colour=model), linetype=2, size=0.5) + 
#   facet_grid(site_id~.) + scale_color_manual(values=cols, name='Method')+
#   scale_fill_manual(values=cols_fill, name='Method')+
#   theme_bw() + theme(axis.title=element_text(size=14), axis.text=element_text(size=14)) +
#   ylab("Biomass (Mg/ha)") + xlab('Year') +
#   scale_x_continuous(breaks=seq(min(years), max(years), by=5))
# ggsave(file=paste0('figures/AGB_by_site_', mvers, '.pdf'))
# ggsave(file=paste0('figures/AGB_by_site_', mvers, '.png'))

####################################################################################################################################
burn=200

plot_sig(post, burn, figure_dir, location, mvers)

#########################################################################################################################################

b0 = sapply(post, function(x) x[,get_cols(x,'b0')][burn:nrow(x)])
colMeans(b0)
b0 = melt(b0)
colnames(b0) =c('iter', 'model', 'value')

b1 = sapply(post, function(x) x[,get_cols(x,'b1')][burn:nrow(x)])
colMeans(b1)
b1 = melt(b1)
colnames(b1) =c('iter', 'model', 'value')

b = rbind(data.frame(b0, par=rep('b0')),
          data.frame(b1, par=rep('b1')))

b$model = models[b$model]

ggplot(data=b) + geom_line(aes(x=iter, y=value, colour=factor(model))) + facet_grid(par~., scales="free_y")+ 
  labs(colour='Data')
ggsave(file=paste0('figures/', figures_dir, '/b_trace_',  location , '_', mvers  ,'.pdf'))

#########################################################################################################################################

tau2 = sapply(post, function(x) x[,get_cols(x,'tau2')][burn:nrow(x)])
colMeans(tau2)
tau2 = melt(tau2)
colnames(tau2) = c('iter', 'model', 'value')

tau3 = sapply(post, function(x) x[,get_cols(x,'tau3')][burn:nrow(x)])
colMeans(tau3)
tau3 = melt(tau3)
colnames(tau3) = c('iter', 'model', 'value')

tau4 = sapply(post, function(x) x[,get_cols(x,'tau4')][burn:nrow(x)])
colMeans(tau4)
tau4 = melt(tau4)
colnames(tau4) = c('iter', 'model', 'value')

tau = rbind(data.frame(tau2, par=rep('tau2')),
            data.frame(tau3, par=rep('tau3')),
            data.frame(tau4, par=rep('tau4')))

tau$model = models[tau$model]

ggplot(data=tau) + geom_line(aes(x=iter, y=value, colour=factor(model))) + facet_grid(par~., scales="free_y")+ 
  labs(colour='Data')
ggsave(file=paste0('figures/', figures_dir, '/tau_trace_',  location , '_', mvers  ,'.pdf'))


tau_fig <- ggplot(data=tau, aes(x=value, y=..scaled..)) + #geom_histogram(aes(value, colour=model, fill=model), binwidth=0.02, stat='bin') + 
  geom_density(aes(colour=model, fill=model),alpha=.2) + facet_wrap(~par, nrow=3, dir="v", strip.position="right") + 
  labs(colour='Method') + 
  labs(fill='Method') + ylab('Density') + xlab('Value') + theme_bw() + 
  theme(strip.text = element_text(size = 12), legend.text = element_text(size=12),
        legend.title = element_text(size=12), axis.title = element_text(size=12), axis.text = element_text(size=12),
        strip.background = element_rect(colour = NA))
print(tau_fig)

ggsave(file=paste0('figures/', figures_dir, '/tau_density_',  location , '_', mvers  ,'.pdf'))
ggsave(file=paste0('figures/', figures_dir, '/tau_density_',  location , '_', mvers  ,'.png'))


#########################################################################################################################################
## plot together for paper
#########################################################################################################################################

all_pars = rbind(sig_rw, sig_d, tau)

ggplot(data=all_pars, aes(x=value, y=..scaled..)) + #geom_histogram(aes(value, colour=model, fill=model), binwidth=0.02, stat='bin') + 
  geom_density(data=all_pars, aes(colour=model, fill=model),alpha=.2)+ facet_wrap(~par, nrow=3, dir="v")+#, scales="free_x", ) + 
  labs(colour='Method') + 
  labs(fill='Method') + ylab('Density') + xlab('Value') + 
  theme(strip.text = element_text(size = 12), legend.text = element_text(size=12),legend.title = element_text(size=12), axis.title = element_text(size=12), axis.text = element_text(size=12))

ggsave(file=paste0('figures/', figures_dir, '/all_pars_density_',  location , '_', mvers  ,'.pdf'))
ggsave(file=paste0('figures/', figures_dir, '/all_pars_density_', location , '_', mvers  ,'.png'))


