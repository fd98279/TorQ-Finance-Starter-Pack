quote:([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$(); src:`symbol$())
trade:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); stop:`boolean$(); cond:`char$(); ex:`char$();side:`symbol$())
eodwsraw:([]time:`timestamp$(); providerts:`timestamp$(); sym:`symbol$(); kind:`symbol$(); price:`float$(); bid:`float$(); ask:`float$(); size:`long$(); bsize:`long$(); asize:`long$(); raw:(); src:`symbol$())
packets:([] time:`timestamp$(); sym:`symbol$(); src:`symbol$(); dest:`symbol$(); srcport:`long$(); destport:`long$(); seq:`long$(); ack:`long$(); win:`long$(); tsval:`long$(); tsecr:`long$(); flags:(); protocol:`symbol$(); length:`long$(); len:`long$(); data:())



