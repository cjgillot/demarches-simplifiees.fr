# == Schema Information
#
# Table name: traitements
#
#  id                :bigint           not null, primary key
#  instructeur_email :string
#  motivation        :string
#  process_expired   :boolean
#  processed_at      :datetime
#  state             :string
#  dossier_id        :bigint
#
class Traitement < ApplicationRecord
  belongs_to :dossier, optional: false

  scope :termine_close_to_expiration, -> do
    joins(dossier: :procedure)
      .where(state: Dossier::TERMINE)
      .where(process_expired: true)
      .where('dossiers.state' => Dossier::TERMINE)
      .where("traitements.processed_at + (procedures.duree_conservation_dossiers_dans_ds * INTERVAL '1 month') - INTERVAL :expires_in < :now", { now: Time.zone.now, expires_in: Dossier::INTERVAL_BEFORE_EXPIRATION })
  end

  scope :for_traitement_time_stats, -> (procedure) do
    includes(:dossier)
      .where(dossier: procedure.dossiers)
      .where.not('dossiers.en_construction_at' => nil, :processed_at => nil)
      .order(:processed_at)
  end

  def self.count_dossiers_termines_by_month(groupe_instructeurs)
    last_traitements_per_dossier = Traitement
      .select('max(traitements.processed_at) as processed_at')
      .where(dossier: Dossier.state_termine.where(groupe_instructeur: groupe_instructeurs))
      .group(:dossier_id)
      .to_sql

    sql = <<~EOF
      select date_trunc('month', r1.processed_at) as month, count(r1.processed_at)
      from (#{last_traitements_per_dossier}) as r1
      group by date_trunc('month', r1.processed_at)
      order by month desc
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end
end
