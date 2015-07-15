# source('//groups/data/CTRHS/Crn/voc/enrollment/out_ute/vdw_outside_utilization_qa_wp01v02/sas/make_graphs.R')
# source('C:/Users/pardre1/Documents/make_graphs.R')

library(ggplot2)

rat <- read.table("C:/Users/pardre1/Desktop/completeness_rates.txt", sep="\t", header=TRUE)
rat$date <- as.Date(rat$first_day, format = '%d%b%Y')


# Removed the commas from these vars and they are now properly interpreted as numerics.
# rat$num_events    <- as.numeric(rat$num_events)
# rat$num_gp_events <- as.numeric(rat$num_gp_events)
# rat$n             <- as.numeric(rat$n)
# rat$n_gp          <- as.numeric(rat$n_gp)
# rat$gp_rate       <- as.numeric(rat$gp_rate)


# Remove the 9-person rx rate that's totally out of wack.
# rat <- subset(rat, rate < 9)
rat <- subset(rat, n > 500)

diplot <- ggplot(rat, aes(x = date, y = rate, col = capture_status))

diplot <- diplot + geom_point(size = 2.5) + facet_wrap(~ tit, scales = "free_y")

diplot <- diplot + geom_smooth(method="loess") + labs(color="Data Capture")
diplot <- diplot + theme(axis.title.x = element_blank(),
                        legend.position = "bottom",
                        strip.text = element_text(size=rel(1.25)),
                        legend.title = element_text(size=rel(1.25)),
                        legend.text = element_text(size=rel(1.1)) ) +
          ylab("Event Rate (record count)")
          # ggtitle('Data Capture at Group Health')

ggsave('c:/users/pardre1/desktop/completeness_implementation.wmf', width = 12, height = 8, units = 'in')
