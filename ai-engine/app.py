"""Main Streamlit app -- thin orchestration layer over the app/ package."""

import streamlit as st

from app.chunk import process_document
from app.embed import add_to_vector_collection
from app.llm import call_llm
from app.rag import re_rank_cross_encoders
from app.retrieve import query_collection

if __name__ == "__main__":
    st.set_page_config(page_title="RAG Question Answer")

    # Document Upload Area
    with st.sidebar:
        uploaded_file = st.file_uploader(
            "**📑 Upload PDF files for QnA**", type=["pdf"], accept_multiple_files=False
        )

        process = st.button("⚡️ Process")
        if uploaded_file and process:
            normalize_uploaded_file_name = uploaded_file.name.translate(
                str.maketrans({"-": "_", ".": "_", " ": "_"})
            )
            all_splits = process_document(uploaded_file)
            add_to_vector_collection(all_splits, normalize_uploaded_file_name)

    # Question and Answer Area
    st.header("🗣️ RAG Question Answer")
    prompt = st.text_area("**Ask a question related to your document:**")
    ask = st.button("🔥 Ask")

    if ask and prompt:
        results = query_collection(prompt)
        context = results.get("documents")[0]
        relevant_text, relevant_text_ids = re_rank_cross_encoders(prompt, context)
        response = call_llm(context=relevant_text, prompt=prompt)
        st.write_stream(response)

        with st.expander("See retrieved documents"):
            st.write(results)

        with st.expander("See most relevant document ids"):
            st.write(relevant_text_ids)
            st.write(relevant_text)
