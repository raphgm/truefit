import React from "react";
import { Printer, X } from "lucide-react";
import { MeasurementKey, TailoringOrder } from "../types";

interface CutSheetModalProps {
  order: TailoringOrder | null;
  onClose: () => void;
}

const KEYS: MeasurementKey[] = [
  "Chest",
  "Waist",
  "Hip",
  "Shoulder",
  "Sleeve",
  "Inseam",
];

export const CutSheetModal: React.FC<CutSheetModalProps> = ({
  order,
  onClose,
}) => {
  if (!order) return null;

  return (
    <div
      className="fixed inset-0 z-[70] flex items-center justify-center bg-[#211D2B]/60 backdrop-blur-sm p-4 print:bg-white print:p-0"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="cutsheet-title"
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-2xl bg-white rounded-3xl p-6 sm:p-8 shadow-2xl max-h-[90vh] overflow-y-auto print:shadow-none print:rounded-none print:max-h-none"
      >
        <div className="flex items-start justify-between gap-4 pb-5 border-b border-[#211D2B]/12">
          <div>
            <p className="text-xs font-mono uppercase tracking-wider text-[#6E687B]">
              Bespoke Pattern Cut-Sheet · {order.id}
            </p>
            <h2
              id="cutsheet-title"
              className="font-display text-2xl sm:text-3xl font-bold text-[#211D2B] mt-1"
            >
              {order.outfitName}
            </h2>
            <p className="text-xs text-[#6E687B] mt-1">
              {order.atelierName} · Profile: {order.fitProfileLabel} · Ordered{" "}
              {order.createdAt}
            </p>
          </div>
          <div className="flex items-center gap-2 print:hidden">
            <button
              type="button"
              onClick={() => window.print()}
              className="px-4 py-2.5 rounded-xl bg-[#7654E8] text-white text-xs font-semibold inline-flex items-center gap-1.5 hover:bg-[#6442D6] min-h-[40px]"
            >
              <Printer className="w-4 h-4" />
              <span>Print</span>
            </button>
            <button
              type="button"
              aria-label="Close cut-sheet"
              onClick={onClose}
              className="w-10 h-10 rounded-full border border-[#211D2B]/12 flex items-center justify-center text-[#211D2B] hover:bg-[#FAF8FC]"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-12 gap-6 py-6">
          <div className="sm:col-span-4">
            <img
              src={order.outfitImage}
              alt={order.outfitName}
              referrerPolicy="no-referrer"
              className="w-full aspect-[3/4] object-cover rounded-2xl border border-[#211D2B]/10"
            />
          </div>

          <div className="sm:col-span-8 space-y-5">
            <div>
              <h3 className="text-xs font-bold uppercase tracking-wider text-[#6E687B] mb-2.5">
                Garment Measurements
              </h3>
              <div className="border border-[#211D2B]/10 rounded-2xl overflow-hidden">
                <table className="w-full text-xs">
                  <thead className="bg-[#FAF8FC] text-[#6E687B]">
                    <tr>
                      <th className="text-left px-4 py-2.5 font-semibold">
                        Dimension
                      </th>
                      <th className="text-right px-4 py-2.5 font-semibold">
                        Metric (cm)
                      </th>
                      <th className="text-right px-4 py-2.5 font-semibold">
                        Imperial (in)
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#211D2B]/8 font-mono tabular-nums">
                    {KEYS.map((k) => {
                      const cm = order.measurementsSnapshot[k];
                      return (
                        <tr key={k}>
                          <td className="px-4 py-2.5 font-sans font-semibold text-[#211D2B]">
                            {k}
                          </td>
                          <td className="px-4 py-2.5 text-right text-[#211D2B]">
                            {cm.toFixed(1)} cm
                          </td>
                          <td className="px-4 py-2.5 text-right text-[#6E687B]">
                            {(cm / 2.54).toFixed(1)} in
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            <dl className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs bg-[#FAF8FC] rounded-2xl p-4 border border-[#211D2B]/8">
              <div>
                <dt className="text-[#6E687B]">Fabric Selection</dt>
                <dd className="font-semibold text-[#211D2B] mt-0.5">
                  {order.fabricChoice}
                </dd>
              </div>
              <div>
                <dt className="text-[#6E687B]">Target Event Date</dt>
                <dd className="font-semibold text-[#211D2B] mt-0.5">
                  {order.eventDate || "Standard turnaround"}
                  {order.isRushOrder ? " (Rush)" : ""}
                </dd>
              </div>
              <div>
                <dt className="text-[#6E687B]">Fitting Slot</dt>
                <dd className="font-semibold text-[#211D2B] mt-0.5">
                  {order.appointmentSlot || "Measurements attached"}
                </dd>
              </div>
              <div>
                <dt className="text-[#6E687B]">Payment Milestone</dt>
                <dd className="font-semibold text-[#211D2B] mt-0.5">
                  {order.paymentStatus}
                </dd>
              </div>
              <div className="sm:col-span-2">
                <dt className="text-[#6E687B]">Client Notes</dt>
                <dd className="font-medium text-[#211D2B] mt-0.5">
                  {order.fabricNote}
                </dd>
              </div>
              {order.tailorGuidance && (
                <div className="sm:col-span-2">
                  <dt className="text-[#6E687B]">AI Ease &amp; Construction Notes</dt>
                  <dd className="font-medium text-[#211D2B] mt-0.5">
                    {order.tailorGuidance}
                  </dd>
                </div>
              )}
            </dl>
          </div>
        </div>
      </div>
    </div>
  );
};
